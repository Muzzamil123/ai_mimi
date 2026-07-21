interface PaginationMeta {
  page: number
  total_pages: number
}

interface PaginationProps {
  meta: PaginationMeta
  onPageChange: (page: number) => void
}

/** Previous/Next pager driven by list `meta`. Shared across admin list pages. */
export function Pagination({ meta, onPageChange }: PaginationProps) {
  return (
    <div className="pagination">
      <button
        type="button"
        disabled={meta.page <= 1}
        onClick={() => onPageChange(Math.max(1, meta.page - 1))}
      >
        Previous
      </button>
      <span>
        Page {meta.page} of {meta.total_pages || 1}
      </span>
      <button
        type="button"
        disabled={meta.page >= meta.total_pages}
        onClick={() => onPageChange(meta.page + 1)}
      >
        Next
      </button>
    </div>
  )
}
