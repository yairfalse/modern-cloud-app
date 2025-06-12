/**
 * BlogPost interface representing a blog post entity
 */
export interface BlogPost {
  /** Unique identifier for the blog post */
  id: string;
  /** Title of the blog post */
  title: string;
  /** Full content of the blog post */
  content: string;
  /** First 150 characters of the content for preview */
  excerpt: string;
  /** Name of the post author */
  authorName: string;
  /** Unique identifier of the author */
  authorId: string;
  /** ISO date string when the post was created */
  createdAt: string;
  /** ISO date string when the post was last updated */
  updatedAt: string;
  /** Whether the post is published or draft */
  published: boolean;
}

/**
 * User interface representing a user entity
 */
export interface User {
  /** Unique identifier for the user */
  id: string;
  /** User's display name */
  name: string;
  /** User's email address */
  email: string;
  /** ISO date string when the user was created */
  createdAt: string;
}

/**
 * Comment interface representing a comment on a blog post
 */
export interface Comment {
  /** Unique identifier for the comment */
  id: string;
  /** ID of the blog post this comment belongs to */
  postId: string;
  /** ID of the user who made the comment */
  userId: string;
  /** Name of the comment author */
  authorName: string;
  /** Content of the comment */
  content: string;
  /** ISO date string when the comment was created */
  createdAt: string;
}

/**
 * Generic API response wrapper
 * @template T - The type of data being returned
 */
export interface ApiResponse<T> {
  /** The response data */
  data: T;
  /** Optional success message */
  message?: string;
  /** Optional error message */
  error?: string;
}