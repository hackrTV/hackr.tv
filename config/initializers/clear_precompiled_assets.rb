# In development, precompiled assets in public/assets/ override live files
# from app/assets/, silently preventing edits from taking effect.
# Clear them on boot so Propshaft always serves from source.
if Rails.env.development?
  manifest = Rails.root.join("public/assets/.manifest.json")
  if manifest.exist?
    FileUtils.rm_rf(Rails.root.join("public/assets"))
    Rails.logger.info "[Assets] Cleared stale precompiled assets from public/assets/"
  end
end
