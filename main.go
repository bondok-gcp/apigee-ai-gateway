package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	"golang.org/x/oauth2/google"
)

// Helper function to handle JSON responses
func jsonResponse(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if data != nil {
		json.NewEncoder(w).Encode(data)
	}
}

// withCORS middleware adds CORS headers for permissive access
func withCORS(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next(w, r)
	}
}

func getGCPClient(ctx context.Context) (*http.Client, error) {
	client, err := google.DefaultClient(ctx, "https://www.googleapis.com/auth/cloud-platform")
	if err != nil {
		return nil, err
	}
	return client, nil
}

func doApigeeRequest(ctx context.Context, method, url string, body interface{}, target interface{}) error {
	client, err := getGCPClient(ctx)
	if err != nil {
		return err
	}

	var reqBody io.Reader
	if body != nil {
		b, _ := json.Marshal(body)
		reqBody = bytes.NewReader(b)
	}

	req, err := http.NewRequest(method, url, reqBody)
	if err != nil {
		return err
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		respBytes, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("apigee API error (%d): %s", resp.StatusCode, string(respBytes))
	}

	if target != nil && resp.StatusCode != http.StatusNoContent {
		return json.NewDecoder(resp.Body).Decode(target)
	}
	return nil
}

func userAnalyticsHandler(w http.ResponseWriter, r *http.Request) {
	projectId := r.PathValue("projectId")
	if projectId == "" {
		projectId = os.Getenv("GOOGLE_CLOUD_PROJECT")
	}
	email := r.PathValue("email")
	if email == "" {
		jsonResponse(w, http.StatusBadRequest, map[string]string{"error": "email is required"})
		return
	}

	if r.Method != http.MethodGet {
		jsonResponse(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}

	ctx := context.Background()

	// Compute timeRange (last 3 months)
	now := time.Now().UTC()
	threeMonthsAgo := now.AddDate(0, -3, 0)
	timeRange := fmt.Sprintf("%02d/%02d/%04d %02d:%02d~%02d/%02d/%04d %02d:%02d",
		threeMonthsAgo.Month(), threeMonthsAgo.Day(), threeMonthsAgo.Year(), threeMonthsAgo.Hour(), threeMonthsAgo.Minute(),
		now.Month(), now.Day(), now.Year(), now.Hour(), now.Minute())

	escapedTimeRange := strings.Replace(url.QueryEscape(timeRange), "+", "%20", -1)
	escapedFilter := strings.Replace(url.QueryEscape(fmt.Sprintf("(developer_email eq '%s')", email)), "+", "%20", -1)

	var appStats []interface{}
	var productStats []interface{}
	var modelStats []interface{}

	// Get all environments for this org
	envUrl := fmt.Sprintf("https://apigee.googleapis.com/v1/organizations/%s/environments", projectId)
	var envs []string
	if err := doApigeeRequest(ctx, "GET", envUrl, nil, &envs); err != nil {
		log.Printf("Failed to get environments for org %s: %v", projectId, err)
		jsonResponse(w, http.StatusNotFound, map[string]string{"error": "no data found"})
		return
	}

	for _, env := range envs {
		// 1. Stats by developer_app
		appStatsUrl := fmt.Sprintf("https://apigee.googleapis.com/v1/organizations/%s/environments/%s/stats/developer_app?select=sum(message_count),sum(dc_ai_prompt_token_count),sum(dc_ai_response_token_count),avg(dc_ai_time_first_token)&timeUnit=day&timeRange=%s&filter=%s",
			projectId, env, escapedTimeRange, escapedFilter)

		var appStatsResp map[string]interface{}
		if err := doApigeeRequest(ctx, "GET", appStatsUrl, nil, &appStatsResp); err != nil {
			log.Printf("Failed to get app stats for org %s env %s: %v", projectId, env, err)
		} else {
			delete(appStatsResp, "metaData")
			appStats = append(appStats, appStatsResp)
		}

		// 2. Stats by api_product
		prodStatsUrl := fmt.Sprintf("https://apigee.googleapis.com/v1/organizations/%s/environments/%s/stats/api_product?select=sum(message_count),sum(dc_ai_prompt_token_count),sum(dc_ai_response_token_count),avg(dc_ai_time_first_token)&timeUnit=day&timeRange=%s&filter=%s",
			projectId, env, escapedTimeRange, escapedFilter)

		var prodStatsResp map[string]interface{}
		if err := doApigeeRequest(ctx, "GET", prodStatsUrl, nil, &prodStatsResp); err != nil {
			log.Printf("Failed to get product stats for org %s env %s: %v", projectId, env, err)
		} else {
			delete(prodStatsResp, "metaData")
			productStats = append(productStats, prodStatsResp)
		}

		// 3. Stats by dc_ai_model
		modelStatsUrl := fmt.Sprintf("https://apigee.googleapis.com/v1/organizations/%s/environments/%s/stats/dc_ai_model?select=sum(dc_ai_prompt_token_count),sum(dc_ai_response_token_count),avg(dc_ai_time_first_token),avg(dc_ai_time_first_token)&timeUnit=day&timeRange=%s&filter=%s",
			projectId, env, escapedTimeRange, escapedFilter)

		var modelStatsResp map[string]interface{}
		if err := doApigeeRequest(ctx, "GET", modelStatsUrl, nil, &modelStatsResp); err != nil {
			log.Printf("Failed to get model stats for org %s env %s: %v", projectId, env, err)
		} else {
			delete(modelStatsResp, "metaData")
			modelStats = append(modelStats, modelStatsResp)
		}
	}

	jsonResponse(w, http.StatusOK, map[string]interface{}{
		"app":     appStats,
		"product": productStats,
		"model":   modelStats,
	})
}

func configHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		jsonResponse(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}

	projectId := os.Getenv("GOOGLE_CLOUD_PROJECT")
	jsonResponse(w, http.StatusOK, map[string]interface{}{
		"googleCloudProject": projectId,
	})
}

func main() {

	mux := http.NewServeMux()

	landingFs := http.FileServer(http.Dir("public"))
	mux.Handle("/", landingFs)

	mux.HandleFunc("/api/projects/{projectId}/users/{email}/analytics", withCORS(userAnalyticsHandler))
	mux.HandleFunc("/api/config", withCORS(configHandler))

	log.Println("Server listening on :8080")
	if err := http.ListenAndServe(":8080", mux); err != nil {
		log.Fatal(err)
	}
}
