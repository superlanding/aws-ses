#!/bin/bash

# Full test script for multiple Ruby versions (includes development dependencies)
# Note: This requires nokogiri to compile, which may fail on ARM Macs with old Ruby versions
set -e

RUBY_VERSIONS=("2.7.6" "3.0.7" "3.1.7")
FAILED_VERSIONS=()
PASSED_VERSIONS=()

echo "======================================"
echo "Full Testing aws-ses across Ruby versions"
echo "(Including test suite)"
echo "======================================"
echo ""

for version in "${RUBY_VERSIONS[@]}"; do
  echo "--------------------------------------"
  echo "Testing with Ruby $version"
  echo "--------------------------------------"

  # Check if version is installed
  if ! rbenv versions | grep -q "$version"; then
    echo "❌ Ruby $version is not installed. Please install it with:"
    echo "   rbenv install $version"
    FAILED_VERSIONS+=("$version (not installed)")
    echo ""
    continue
  fi

  # Set Ruby version
  rbenv local "$version"

  # Show Ruby version
  echo "Ruby version: $(ruby -v)"

  # Determine which Gemfile to use based on Ruby version
  RUBY_MAJOR_MINOR="${version%.*}"  # Extract major.minor (e.g., "2.7" from "2.7.6")
  GEMFILE="gemfiles/Gemfile.ruby-${RUBY_MAJOR_MINOR}"

  if [ ! -f "$GEMFILE" ]; then
    echo "❌ Gemfile not found: $GEMFILE"
    FAILED_VERSIONS+=("$version (gemfile not found)")
    echo ""
    continue
  fi

  echo "Using Gemfile: $GEMFILE"

  # Install ALL dependencies including development
  echo "Installing all dependencies (including development)..."
  if BUNDLE_GEMFILE="$GEMFILE" bundle install 2>&1 | tail -5; then
    echo "✅ Dependencies installed successfully"
  else
    echo "❌ Failed to install dependencies"
    FAILED_VERSIONS+=("$version (bundle install failed)")
    echo ""
    continue
  fi

  # Test loading the gem
  echo "Testing gem loading..."
  if ruby -I lib -e "require 'aws/ses'; puts 'Successfully loaded aws-ses gem'"; then
    echo "✅ Gem loaded successfully"
  else
    echo "❌ Failed to load gem"
    FAILED_VERSIONS+=("$version (gem load failed)")
    echo ""
    continue
  fi

  # Run full test suite
  echo "Running full test suite..."
  if BUNDLE_GEMFILE="$GEMFILE" bundle exec rake test 2>&1; then
    echo "✅ All tests passed"
    PASSED_VERSIONS+=("$version")
  else
    echo "❌ Tests failed"
    FAILED_VERSIONS+=("$version (tests failed)")
    echo ""
    continue
  fi

  echo ""
done

# Restore original Ruby version
if [ -f .ruby-version ]; then
  rbenv local --unset 2>/dev/null || true
fi

# Summary
echo "======================================"
echo "Summary"
echo "======================================"
echo ""

if [ ${#PASSED_VERSIONS[@]} -gt 0 ]; then
  echo "✅ Passed versions:"
  for version in "${PASSED_VERSIONS[@]}"; do
    echo "   - $version"
  done
  echo ""
fi

if [ ${#FAILED_VERSIONS[@]} -gt 0 ]; then
  echo "❌ Failed versions:"
  for version in "${FAILED_VERSIONS[@]}"; do
    echo "   - $version"
  done
  echo ""
  exit 1
else
  echo "🎉 All Ruby versions passed with full test suite!"
  exit 0
fi
