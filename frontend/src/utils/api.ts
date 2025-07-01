import type { HealthCheckResponse, RootResponse, ApiError } from '../types/api'

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080'

class ApiClient {
  private baseUrl: string

  constructor(baseUrl: string = API_BASE_URL) {
    this.baseUrl = baseUrl
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${this.baseUrl}${endpoint}`

    const config: RequestInit = {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    }

    try {
      const response = await fetch(url, config)

      if (!response.ok) {
        const errorData: ApiError = await response.json().catch(() => ({
          error: `HTTP ${response.status}: ${response.statusText}`,
        }))
        throw new Error(errorData.error)
      }

      return await response.json()
    } catch (error) {
      if (error instanceof Error) {
        throw error
      }
      throw new Error('An unexpected error occurred')
    }
  }

  // Health check endpoints
  async getHealth(): Promise<HealthCheckResponse> {
    return this.request<HealthCheckResponse>('/health')
  }

  async getRoot(): Promise<RootResponse> {
    return this.request<RootResponse>('/')
  }

  // Test connection method
  async testConnection(): Promise<{
    success: boolean
    data?: RootResponse | HealthCheckResponse
    error?: string
  }> {
    try {
      const data = await this.getRoot()
      return { success: true, data }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }
}

export const apiClient = new ApiClient()
export default apiClient
