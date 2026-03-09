---
name: deploy
description: Build, package, and release the macOS app to GitHub Releases
disable-model-invocation: true
argument-hint: "[patch|minor|major]"
---

# Deploy GitHubReview

Release the macOS app by building a DMG and creating a GitHub release.

You MUST follow every step below in order. Do NOT skip any step.

## Step 1: Pre-flight checks

1. Run `git status` to check for uncommitted changes. If the working tree is NOT clean, **abort immediately** and tell the user to commit or stash their changes first.
2. Run `git branch --show-current` to verify we are on the `main` branch. If not, **abort** and tell the user to switch to main.
3. Run `git pull origin main` to pull the latest changes.

## Step 2: Determine version

1. Read the current `MARKETING_VERSION` from `GitHubReview/GitHubReview.xcodeproj/project.pbxproj`.
2. Parse it as semver (MAJOR.MINOR.PATCH).
3. Check if `$ARGUMENTS` is provided (patch, minor, or major):
   - If provided, use that bump type.
   - If NOT provided, ask the user which version bump they want: patch, minor, or major. Show the current version and what each option would produce. Wait for their response before continuing.
4. Calculate the new version based on the bump type:
   - `patch`: increment PATCH (e.g., 1.0.2 -> 1.0.3)
   - `minor`: increment MINOR, reset PATCH (e.g., 1.0.2 -> 1.1.0)
   - `major`: increment MAJOR, reset MINOR and PATCH (e.g., 1.0.2 -> 2.0.0)
5. Update ALL occurrences of `MARKETING_VERSION` in the pbxproj file to the new version using `replace_all: true`.

## Step 3: Build release archive

1. Run: `cd <project-root>/GitHubReview && xcodebuild -scheme GitHubReview -configuration Release -archivePath /tmp/GitHubReview.xcarchive archive`
2. If the build fails, **abort** and show the error.

## Step 4: Create DMG

Run the following:
```
DMG_DIR=/tmp/GitHubReview-dmg
rm -rf "$DMG_DIR" && mkdir -p "$DMG_DIR"
cp -R /tmp/GitHubReview.xcarchive/Products/Applications/GitHubReview.app "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"
hdiutil create -volname "GitHubReview" -srcfolder "$DMG_DIR" -ov -format UDZO /tmp/GitHubReview-v<NEW_VERSION>.dmg
```

## Step 5: Generate release notes

1. Find the previous release tag by running: `gh release list --limit 1`
2. Get all commits since the last release: `git log <previous_tag>..HEAD --oneline`
3. Read through the commit messages and categorize changes into:
   - **New Features** — new functionality
   - **Improvements** — enhancements to existing features
   - **Bug Fixes** — fixes
4. Write release notes in this format:
```
## GitHub Review v<NEW_VERSION>

### New Features
- Feature description

### Improvements
- Improvement description

### Bug Fixes
- Fix description

### Installation
1. Download `GitHubReview-v<NEW_VERSION>.dmg`
2. Open the DMG and drag **GitHubReview** to **Applications**
3. On first launch, right-click the app > **Open** (required for unsigned apps)
```
Only include sections that have entries. Omit empty sections.

## Step 6: Commit, push, and release

1. Stage the pbxproj file: `git add GitHubReview/GitHubReview.xcodeproj/project.pbxproj`
2. Commit with message: `Bump version to <NEW_VERSION>` and the co-author trailer.
3. Push to origin main: `git push origin main`
4. Create the GitHub release:
```
gh release create v<NEW_VERSION> /tmp/GitHubReview-v<NEW_VERSION>.dmg --title "v<NEW_VERSION>" --notes "<release_notes>"
```
5. Show the release URL to the user.

## Important

- The project root is at `/Users/tshan/Repo/tshan/mac-github-review`
- The Xcode project is inside `GitHubReview/` subdirectory
- Always use HEREDOC for commit messages and release notes to preserve formatting
- If ANY step fails, stop and report the error — do not continue
