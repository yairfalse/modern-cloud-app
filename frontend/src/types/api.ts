import type { BlogPost } from './index'

// API endpoint response types
export interface GetPostsResponse {
  data: BlogPost[]
}

export interface GetPostResponse {
  data: BlogPost
}

export interface CreatePostResponse {
  data: BlogPost
}

export interface UpdatePostResponse {
  message: string
}

export interface DeletePostResponse {
  message: string
}

export interface HealthCheckResponse {
  status: 'healthy' | 'unhealthy'
}

// Request payload types
export interface CreatePostPayload {
  title: string
  content: string
  author: string
}

export type UpdatePostPayload = CreatePostPayload

// Generic API error response
export interface ApiError {
  error: string
}
