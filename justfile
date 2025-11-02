# justfile - Build automation for mani_skill

# List available commands
default:
    @just --list

# Build stable release wheel + sdist
build:
    uv build

# Build nightly release with timestamp version
build-nightly:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Generate nightly version: YYYY.M.D.HHMM
    VERSION=$(date +"%Y.%-m.%-d.%H%M")
    
    # Backup original config
    cp pyproject.toml pyproject.toml.bak
    
    # Modify for nightly (macOS/Linux compatible)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS sed requires backup extension
        sed -i.tmp "s/^version = .*/version = \"$VERSION\"/" pyproject.toml
        sed -i.tmp "s/^name = \"mani_skill\"/name = \"mani_skill-nightly\"/" pyproject.toml
        rm -f pyproject.toml.tmp
    else
        # GNU sed
        sed -i "s/^version = .*/version = \"$VERSION\"/" pyproject.toml
        sed -i "s/^name = \"mani_skill\"/name = \"mani_skill-nightly\"/" pyproject.toml
    fi
    
    # Build
    uv build
    
    # Restore original
    mv pyproject.toml.bak pyproject.toml
    
    echo "Built mani_skill-nightly version $VERSION"

# Clean build artifacts
clean:
    rm -rf dist/ build/ *.egg-info
    find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
    find . -type f -name "*.pyc" -delete

# Install package in development mode
install-dev:
    uv pip install -e ".[dev]"

# Run tests
test:
    pytest tests/

# Publish to PyPI (requires TWINE_USERNAME and TWINE_PASSWORD env vars)
publish-stable: clean build
    uv publish

# Publish nightly to PyPI
publish-nightly: clean build-nightly
    uv publish

# Test build locally without publishing
test-build: clean build
    ls -lh dist/
    unzip -l dist/*.whl | head -n 20

# Check pyproject.toml validity
check-config:
    uv pip install --dry-run -e .
