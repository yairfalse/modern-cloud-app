// BlogPost interface matching the backend Go struct
export interface BlogPost {
  id: number;
  title: string;
  content: string;
  author: string;
  created_at: string; // ISO date string
}

// User interface for authentication
export interface User {
  id: number;
  username: string;
  email: string;
  created_at: string;
}

// API Response types
export interface ApiResponse<T = any> {
  data?: T;
  error?: string;
  message?: string;
}

export interface BlogPostsResponse extends ApiResponse {
  data: BlogPost[];
}

export interface BlogPostResponse extends ApiResponse {
  data: BlogPost;
}

export interface HealthResponse extends ApiResponse {
  status: string;
}

// Form types for creating/updating posts
export interface CreateBlogPostRequest {
  title: string;
  content: string;
  author: string;
}

export interface UpdateBlogPostRequest extends CreateBlogPostRequest {}

// Error response type
export interface ErrorResponse {
  error: string;
}