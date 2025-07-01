import { useState, useEffect } from 'react'
import apiClient from '../utils/api'
import type { RootResponse, HealthCheckResponse } from '../types/api'

interface ConnectionStatus {
  isConnected: boolean
  isLoading: boolean
  error?: string
  backendInfo?: RootResponse
  healthInfo?: HealthCheckResponse
}

export default function Home() {
  const [connectionStatus, setConnectionStatus] = useState<ConnectionStatus>({
    isConnected: false,
    isLoading: true,
  })

  useEffect(() => {
    checkBackendConnection()
  }, [])

  const checkBackendConnection = async () => {
    setConnectionStatus(prev => ({
      ...prev,
      isLoading: true,
      error: undefined,
    }))

    try {
      // Test basic connection first
      const connectionTest = await apiClient.testConnection()

      if (connectionTest.success) {
        // Get additional health info
        const healthInfo = await apiClient.getHealth()

        setConnectionStatus({
          isConnected: true,
          isLoading: false,
          backendInfo: connectionTest.data as RootResponse,
          healthInfo,
        })
      } else {
        setConnectionStatus({
          isConnected: false,
          isLoading: false,
          error: connectionTest.error,
        })
      }
    } catch (error) {
      setConnectionStatus({
        isConnected: false,
        isLoading: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      })
    }
  }

  const StatusIndicator = ({
    isConnected,
    isLoading,
  }: {
    isConnected: boolean
    isLoading: boolean
  }) => {
    if (isLoading) {
      return (
        <div className="w-3 h-3 bg-yellow-400 rounded-full animate-pulse"></div>
      )
    }
    return (
      <div
        className={`w-3 h-3 rounded-full ${isConnected ? 'bg-green-400' : 'bg-red-400'}`}
      ></div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <div className="max-w-2xl mx-auto bg-white rounded-lg shadow-md p-6">
        <h1 className="text-3xl font-bold text-gray-900 mb-6">
          ModernBlog Frontend
        </h1>
        <p className="text-gray-600 mb-6">
          React + TypeScript frontend connected to Go backend API.
        </p>

        {/* Backend Connection Status */}
        <div className="border rounded-lg p-4 mb-4">
          <div className="flex items-center gap-2 mb-3">
            <StatusIndicator
              isConnected={connectionStatus.isConnected}
              isLoading={connectionStatus.isLoading}
            />
            <h2 className="text-lg font-semibold">Backend Connection</h2>
            <button
              onClick={checkBackendConnection}
              disabled={connectionStatus.isLoading}
              className="ml-auto px-3 py-1 text-sm bg-blue-500 text-white rounded hover:bg-blue-600 disabled:opacity-50"
            >
              {connectionStatus.isLoading ? 'Testing...' : 'Refresh'}
            </button>
          </div>

          {connectionStatus.isLoading && (
            <p className="text-yellow-600">Connecting to backend...</p>
          )}

          {connectionStatus.error && (
            <div className="bg-red-50 border border-red-200 rounded p-3">
              <p className="text-red-800 font-medium">Connection Failed</p>
              <p className="text-red-600 text-sm mt-1">
                {connectionStatus.error}
              </p>
            </div>
          )}

          {connectionStatus.isConnected && connectionStatus.backendInfo && (
            <div className="bg-green-50 border border-green-200 rounded p-3">
              <p className="text-green-800 font-medium">
                ✅ Connected Successfully!
              </p>
              <div className="mt-2 text-sm space-y-1">
                <p>
                  <span className="font-medium">Message:</span>{' '}
                  {connectionStatus.backendInfo.message}
                </p>
                <p>
                  <span className="font-medium">Version:</span>{' '}
                  {connectionStatus.backendInfo.version}
                </p>
                <p>
                  <span className="font-medium">Mode:</span>{' '}
                  {connectionStatus.backendInfo.mode}
                </p>
                <p>
                  <span className="font-medium">Server Time:</span>{' '}
                  {new Date(connectionStatus.backendInfo.time).toLocaleString()}
                </p>
              </div>
            </div>
          )}

          {connectionStatus.healthInfo && (
            <div className="bg-blue-50 border border-blue-200 rounded p-3 mt-2">
              <p className="text-blue-800 font-medium">Health Check</p>
              <div className="mt-1 text-sm">
                <p>
                  <span className="font-medium">Status:</span>{' '}
                  {connectionStatus.healthInfo.status}
                </p>
                <p>
                  <span className="font-medium">Timestamp:</span>{' '}
                  {new Date(
                    connectionStatus.healthInfo.timestamp
                  ).toLocaleString()}
                </p>
              </div>
            </div>
          )}
        </div>

        <div className="text-sm text-gray-500">
          <p>
            Backend URL:{' '}
            {import.meta.env.VITE_API_URL || 'http://localhost:8080'}
          </p>
        </div>
      </div>
    </div>
  )
}
