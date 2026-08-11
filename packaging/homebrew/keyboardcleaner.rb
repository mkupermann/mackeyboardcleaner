# Homebrew cask for KeyboardCleaner.
#
# Intended for a personal tap (github.com/mkupermann/homebrew-tap), since
# homebrew/homebrew-cask requires project notability (>= 75 stars) for new casks.
#
# After each release, update `version` and `sha256`:
#   shasum -a 256 KeyboardCleaner-<version>.dmg

cask "keyboardcleaner" do
  version "1.2.0"
  sha256 "e31c49f79c1b859650269f4caeacc367a491c9156302e737e20dc1079552c9f7"

  url "https://github.com/mkupermann/mackeyboardcleaner/releases/download/v#{version}/KeyboardCleaner-#{version}.dmg"
  name "KeyboardCleaner"
  desc "Menu bar utility that blocks all keyboard input while you clean"
  homepage "https://github.com/mkupermann/mackeyboardcleaner"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :monterey

  app "KeyboardCleaner.app"

  zap trash: "~/Library/Preferences/com.mkupermann.KeyboardCleaner.plist"

  caveats <<~EOS
    KeyboardCleaner needs Accessibility permission:
    System Settings > Privacy & Security > Accessibility
  EOS
end
