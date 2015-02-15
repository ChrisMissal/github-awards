class LanguageListPresenter
  def languages
    Rails.cache.fetch("languages") { JSON.parse(File.read(Rails.root.join('app', 'assets', 'javascripts', 'languages.json'))) }
  end
end