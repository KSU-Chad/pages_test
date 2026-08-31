# frozen_string_literal: true

module CategoryPath
  PLACEHOLDER = ':name'
  CHIRPY_CATEGORY_ROOT = '/categories/'

  module_function

  def configured_permalink(site)
    site.config.dig('jekyll-archives', 'permalinks', 'category').to_s
  end

  def taxonomy_root(site)
    permalink = configured_permalink(site)

    unless permalink.include?(PLACEHOLDER)
      raise Jekyll::Errors::FatalException,
            "jekyll-archives.permalinks.category must contain #{PLACEHOLDER.inspect}"
    end

    root = permalink.split(PLACEHOLDER, 2).first
    root = "/#{root}" unless root.start_with?('/')
    root = "#{root}/" unless root.end_with?('/')
    root.gsub(%r{/+}, '/')
  end

  def tab_documents(site)
    site.pages + site.collections.values.flat_map(&:docs)
  end

  def set_tab_permalink(site)
    root = taxonomy_root(site)

    tab_documents(site).each do |document|
      next unless document.data['layout'] == 'categories'

      document.data['permalink'] = root
      document.remove_instance_variable(:@url) if document.instance_variable_defined?(:@url)
    end
  end

  def set_post_permalinks(site)
    root = taxonomy_root(site)

    site.posts.docs.each do |post|
      categories = Array(post.data['categories']).reject { |category| category.to_s.empty? }
      next if categories.empty?

      module_slug = Jekyll::Utils.slugify(categories.first.to_s)
      post_slug = Jekyll::Utils.slugify(post.slug.to_s)
      post.data['permalink'] = "#{root}#{module_slug}/#{post_slug}/"
      post.remove_instance_variable(:@url) if post.instance_variable_defined?(:@url)
    end
  end

  def replace_chirpy_category_links(item)
    output = item.output
    return unless output.is_a?(String)

    root = taxonomy_root(item.site)
    baseurl = item.site.baseurl.to_s.chomp('/')

    # Chirpy 7.6 builds category links with the fixed `/categories/` prefix.
    # Replace both relative_url output and root-relative output so this also
    # works when the site has no baseurl.
    unless baseurl.empty?
      output.gsub!("#{baseurl}#{CHIRPY_CATEGORY_ROOT}", "#{baseurl}#{root}")
    end
    output.gsub!(CHIRPY_CATEGORY_ROOT, root)
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  CategoryPath.set_tab_permalink(site)
  CategoryPath.set_post_permalinks(site)
end

Jekyll::Hooks.register %i[pages documents], :post_render do |item|
  CategoryPath.replace_chirpy_category_links(item)
end
