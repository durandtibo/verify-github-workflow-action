# Contributing to verify-github-workflow-action

Thank you for your interest in contributing to verify-github-workflow-action! We welcome
contributions from the community and are grateful for your support.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Code Style](#code-style)
- [Pull Request Process](#pull-request-process)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Enhancements](#suggesting-enhancements)

## Code of Conduct

This project adheres to the Contributor Covenant [Code of Conduct](CODE_OF_CONDUCT.md).
By participating, you are expected to uphold this code. Please report unacceptable behavior
to [durand.tibo+gh@gmail.com](mailto:durand.tibo+gh@gmail.com).

## How to Contribute

There are many ways to contribute to this project:

- Report bugs
- Suggest new features or enhancements
- Improve documentation
- Submit pull requests with bug fixes or new features
- Review pull requests
- Help answer questions in issues

## Development Setup

### Prerequisites

- Git
- A GitHub account
- Basic knowledge of GitHub Actions and YAML

### Setting Up Your Development Environment

1. **Fork the repository**

   Click the "Fork" button at the top right of the repository page.

2. **Clone your fork**

   ```bash
   git clone https://github.com/YOUR-USERNAME/verify-github-workflow-action.git
   cd verify-github-workflow-action
   ```

3. **Add the upstream repository**

   ```bash
   git remote add upstream https://github.com/durandtibo/verify-github-workflow-action.git
   ```

4. **Create a new branch for your changes**

   ```bash
   git checkout -b feature/your-feature-name
   ```

## Making Changes

1. **Keep your fork up to date**

   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

2. **Make your changes**
   - Edit the relevant files
   - Follow the existing code style and conventions
   - Add or update tests as needed
   - Update documentation if necessary

3. **Commit your changes**

   ```bash
   git add .
   git commit -m "Description of your changes"
   ```

   Write clear, concise commit messages that describe what your changes do.

## Testing

Before submitting your changes, ensure they work correctly:

### Testing Locally

You can test the action locally by:

1. Creating a test workflow in your fork that uses the local action:

   ```yaml
   name: Test Local Action
   on: [push]
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v6
         - name: Test action
           uses: ./
   ```

2. Push your branch and check the workflow runs successfully on GitHub Actions

### Running Format Checks

Before submitting a pull request, run the format checks:

```bash
make format
```

This will run:

- `markdownlint` on all Markdown files
- `prettier` to format code
- `yamllint` on all YAML files

If you don't have these tools installed, they will be automatically installed and run
by the CI pipeline when you submit your pull request.

## Code Style

### YAML Style

- Use 2 spaces for indentation
- Keep lines under 100 characters when possible
- Use meaningful names for jobs and steps
- Add comments for complex logic

### Markdown Style

- Use ATX-style headers (`#` for h1, `##` for h2, etc.)
- Keep lines under 100 characters
- Use reference-style links for repeated URLs
- Add blank lines between sections

### Commit Messages

- Use the imperative mood ("Add feature" not "Added feature")
- Keep the first line under 72 characters
- Add a blank line before the detailed description
- Reference issues and pull requests when relevant

## Pull Request Process

1. **Ensure all checks pass**
   - All CI checks must pass
   - Code must be properly formatted
   - Tests must pass on all supported platforms

2. **Update documentation**
   - Update the README.md if you're adding new features
   - Add comments to complex code sections
   - Update relevant examples

3. **Fill out the pull request template**
   - Provide a clear description of your changes
   - Link to any related issues
   - Check all items in the PR checklist

4. **Request a review**
   - Wait for a maintainer to review your PR
   - Address any feedback or requested changes
   - Be patient and respectful during the review process

5. **Merge**
   - Once approved, a maintainer will merge your PR
   - Your contribution will be included in the next release

## Reporting Bugs

If you find a bug, please create an issue using the bug report template. Include:

- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Screenshots or logs if applicable
- Your environment (OS, GitHub Actions runner version, etc.)

## Suggesting Enhancements

We welcome suggestions for new features or improvements! Please create an issue using the
feature request template and include:

- A clear, descriptive title
- A detailed description of the proposed feature
- Examples of how it would be used
- Any potential drawbacks or alternatives you've considered

## Questions?

If you have questions about contributing, feel free to:

- Open an issue with the label "question"
- Contact the maintainers at [durand.tibo+gh@gmail.com](mailto:durand.tibo+gh@gmail.com)

Thank you for contributing to verify-github-workflow-action!
