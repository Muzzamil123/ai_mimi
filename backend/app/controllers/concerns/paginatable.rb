# Simple offset pagination for index endpoints. Returns the page of records
# plus a metadata hash for the JSON response.
module Paginatable
  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 100

  private

  def paginate(relation)
    page = [ params.fetch(:page, 1).to_i, 1 ].max
    per_page = params.fetch(:per_page, DEFAULT_PER_PAGE).to_i.clamp(1, MAX_PER_PAGE)

    total_count = relation.count(:all)
    records = relation.limit(per_page).offset((page - 1) * per_page)

    meta = {
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_count.zero? ? 0 : (total_count.to_f / per_page).ceil
    }

    [ records, meta ]
  end
end
