import React, { useState, useEffect } from 'react'
import { useParams, useLocation } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { apiJson } from '~/utils/apiClient'
import { CodeBreadcrumb } from './CodeBreadcrumb'
import { CodeTreeView } from './CodeTreeView'
import { CodeBlobView } from './CodeBlobView'
import type { CodeRepository, TreeEntry, RepoDetailResponse, TreeResponse, BlobResponse } from '~/types/code'

export const CodeRepoPage: React.FC = () => {
  const { repo } = useParams<{ repo: string }>()
  const location = useLocation()
  const [repoData, setRepoData] = useState<CodeRepository | null>(null)
  const [treeEntries, setTreeEntries] = useState<TreeEntry[]>([])
  const [blobData, setBlobData] = useState<{ content: string; language: string; name: string; size: number } | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Determine view mode and path from URL
  const pathMatch = location.pathname.match(/^\/code\/[^/]+\/(tree|blob)\/(.+)$/)
  const viewMode: 'root' | 'tree' | 'blob' = pathMatch ? (pathMatch[1] as 'tree' | 'blob') : 'root'
  const currentPath = pathMatch ? pathMatch[2] : ''

  useEffect(() => {
    if (!repo) return

    setLoading(true)
    setError(null)
    setBlobData(null)

    let url: string
    if (viewMode === 'blob') {
      url = `/api/code/${repo}/blob/${currentPath}`
    } else if (viewMode === 'tree') {
      url = `/api/code/${repo}/tree/${currentPath}`
    } else {
      url = `/api/code/${repo}`
    }

    if (viewMode === 'blob') {
      apiJson<BlobResponse>(url)
        .then(data => {
          setRepoData(data.repo)
          setBlobData({ content: data.content, language: data.language, name: data.name, size: data.size })
          setTreeEntries([])
          setLoading(false)
        })
        .catch(err => {
          setError(err.message || 'Failed to load file')
          setLoading(false)
        })
    } else if (viewMode === 'tree') {
      apiJson<TreeResponse>(url)
        .then(data => {
          setRepoData(data.repo)
          setTreeEntries(data.tree)
          setLoading(false)
        })
        .catch(err => {
          setError(err.message || 'Failed to load directory')
          setLoading(false)
        })
    } else {
      apiJson<RepoDetailResponse>(url)
        .then(data => {
          setRepoData(data.repo)
          setTreeEntries(data.tree)
          setLoading(false)
        })
        .catch(err => {
          setError(err.message || 'Failed to load repository')
          setLoading(false)
        })
    }
  }, [repo, viewMode, currentPath])

  if (loading) {
    return (
      <DefaultLayout showAsciiArt={false}>
        <div style={{ maxWidth: '900px', margin: '30px auto' }}>
          <LoadingSpinner message="Loading..." color="purple-168-text" size="large" />
        </div>
      </DefaultLayout>
    )
  }

  if (error) {
    return (
      <DefaultLayout showAsciiArt={false}>
        <div style={{ maxWidth: '900px', margin: '30px auto', textAlign: 'center', color: '#f87171' }}>
          {error}
        </div>
      </DefaultLayout>
    )
  }

  return (
    <DefaultLayout showAsciiArt={false}>
      <div style={{ maxWidth: '900px', margin: '30px auto' }}>
        <div style={{ background: '#1a1a1a', color: '#d0d0d0', padding: '20px', border: '1px solid #333' }}>
          {/* Repo header */}
          {repoData && viewMode === 'root' && (
            <div style={{ marginBottom: '20px', paddingBottom: '15px', borderBottom: '1px solid #333' }}>
              <h1 style={{ margin: '0 0 8px 0', fontSize: '1.4em', color: '#a78bfa' }}>{repoData.name}</h1>
              {repoData.description && (
                <p style={{ margin: '0 0 10px 0', color: '#9ca3af', fontSize: '0.9em' }}>{repoData.description}</p>
              )}
              <div style={{ display: 'flex', gap: '16px', fontSize: '0.8em', color: '#6b7280' }}>
                {repoData.language && <span>{repoData.language}</span>}
                {repoData.stargazers_count > 0 && <span>★ {repoData.stargazers_count}</span>}
                <span>{repoData.default_branch}</span>
              </div>
            </div>
          )}

          {/* Breadcrumb */}
          <CodeBreadcrumb
            repoSlug={repo!}
            path={currentPath || undefined}
            isBlob={viewMode === 'blob'}
          />

          {/* Content */}
          {viewMode === 'blob' && blobData ? (
            <CodeBlobView
              content={blobData.content}
              language={blobData.language}
              name={blobData.name}
              size={blobData.size}
            />
          ) : (
            <CodeTreeView repoSlug={repo!} entries={treeEntries} />
          )}
        </div>
      </div>
    </DefaultLayout>
  )
}

export default CodeRepoPage
