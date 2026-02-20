# Automated Documentation Update Investigation

**Date:** 2026-02-12  
**Repository:** mgt-axiom-server  
**Target Environment:** GitHub Enterprise

## Executive Summary

This document investigates approaches to automatically update documentation through CI/CD processes when code changes. The goal is to keep specifications, diagrams, READMEs, and other documentation synchronized with code through retrospective analysis.

## Current Documentation Structure

### What We Have
- **Architecture documentation**: README.md with Mermaid diagrams
- **ADRs**: `doc/adr/` - Architecture Decision Records
- **Guides**: BigQuery adapter guide, feature documentation
- **Guidelines**: Testing guidelines
- **Code instructions**: `.github/instructions/` - Java and documentation standards
- **PR template**: Basic template for pull requests

### Maintenance Challenges
1. Documentation updates often lag behind code changes
2. Manual updates are error-prone and inconsistent
3. No automated verification of doc-code alignment
4. Diagrams can become outdated quickly
5. API documentation may not reflect actual implementation

## Automated Documentation Approaches

### Approach 1: AI-Powered Documentation Bot (Recommended)

**Concept**: Use AI to analyze code changes and automatically propose documentation updates.

**Workflow**:
```
Code PR → Analyze Changes → Generate Doc Updates → Create Doc PR/Comment
```

**Implementation Options**:

#### Option A: GitHub Actions + OpenAI/Claude API
```yaml
# .github/workflows/auto-doc-update.yml
name: Auto Documentation Update

on:
  pull_request:
    types: [opened, synchronize]
    paths:
      - 'src/**/*.java'
      - 'pom.xml'

jobs:
  analyze-and-document:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          
      - name: Get changed files
        id: changes
        run: |
          git diff --name-only origin/${{ github.base_ref }}...HEAD > changed_files.txt
          
      - name: Analyze code changes
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const changedFiles = fs.readFileSync('changed_files.txt', 'utf8').split('\n');
            
            // Get file diffs
            const diffs = await Promise.all(
              changedFiles.filter(f => f.endsWith('.java')).map(async file => {
                const { data } = await github.rest.repos.compareCommits({
                  owner: context.repo.owner,
                  repo: context.repo.repo,
                  base: context.payload.pull_request.base.sha,
                  head: context.payload.pull_request.head.sha
                });
                return data.files.find(f => f.filename === file);
              })
            );
            
            core.setOutput('diffs', JSON.stringify(diffs));
            
      - name: Generate documentation updates
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          DIFFS: ${{ steps.changes.outputs.diffs }}
        run: |
          python scripts/generate_doc_updates.py
          
      - name: Create documentation PR or comment
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const docUpdates = fs.readFileSync('doc_updates.md', 'utf8');
            
            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.payload.pull_request.number,
              body: `## 📚 Documentation Update Suggestions\n\n${docUpdates}`
            });
```

#### Option B: GitHub Copilot Workspace (Enterprise Feature)
- Leverage GitHub Copilot's workspace features
- Automatically suggest documentation updates in PRs
- Integrated with GitHub Enterprise

**Pros**:
- Understands context deeply
- Can generate meaningful documentation
- Adapts to project style
- Can update diagrams, ADRs, and guides

**Cons**:
- Requires API costs (OpenAI/Claude)
- Needs careful prompt engineering
- May produce incorrect information (hallucinations)

---

### Approach 2: Static Documentation Generators

**Concept**: Extract documentation from code comments and annotations.

**Tools**:
- **JavaDoc** - Java API documentation
- **Doxygen** - Multi-language documentation
- **Swagger/OpenAPI** - API endpoint documentation
- **PlantUML** - Generate diagrams from code

**Implementation**:
```yaml
# .github/workflows/generate-docs.yml
name: Generate Documentation

on:
  push:
    branches: [main, develop]

jobs:
  generate-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up JDK
        uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'temurin'
          
      - name: Generate JavaDoc
        run: mvn javadoc:javadoc
        
      - name: Generate PlantUML diagrams
        uses: cloudbees/plantuml-github-action@master
        with:
          args: -tsvg -o ../doc/diagrams doc/**/*.puml
          
      - name: Commit documentation
        run: |
          git config user.name "Documentation Bot"
          git config user.email "bot@company.com"
          git add target/site/apidocs doc/diagrams
          git diff --staged --quiet || git commit -m "docs: auto-generate API documentation"
          git push
```

**Pros**:
- Reliable and deterministic
- No AI hallucinations
- Works offline
- Free

**Cons**:
- Only extracts what's in code comments
- Doesn't understand high-level context
- Requires discipline in code commenting
- Limited to structural documentation

---

### Approach 3: Hybrid - AI Analysis + Static Generation

**Concept**: Combine both approaches for comprehensive coverage.

**Implementation Strategy**:
1. **Static generators** for API docs and code structure
2. **AI analysis** for architectural documentation and guides
3. **Automated verification** to check doc-code alignment

```yaml
# .github/workflows/hybrid-docs.yml
name: Hybrid Documentation

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  static-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Generate JavaDoc & Diagrams
        run: |
          mvn javadoc:javadoc
          # Generate dependency graphs, class diagrams, etc.
          
  ai-analysis:
    runs-on: ubuntu-latest
    needs: static-docs
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          
      - name: Analyze architectural impact
        run: |
          # Use AI to analyze if changes require ADR updates
          # Check if README architecture diagram needs updates
          # Suggest guideline updates
          python scripts/ai_doc_analyzer.py
          
      - name: Post analysis results
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const analysis = JSON.parse(fs.readFileSync('analysis.json'));
            
            if (analysis.needsDocUpdate) {
              await github.rest.issues.createComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: context.payload.pull_request.number,
                body: analysis.suggestions
              });
            }
```

---

### Approach 4: Pre-Commit Hooks for Local Updates

**Concept**: Catch documentation drift before code is pushed.

**Implementation**:
```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: check-doc-sync
        name: Check documentation sync
        entry: scripts/check_doc_sync.sh
        language: script
        pass_filenames: false
        always_run: true
        
      - id: update-readme-toc
        name: Update README table of contents
        entry: scripts/update_toc.sh
        language: script
        files: ^README\.md$
        
      - id: validate-mermaid
        name: Validate Mermaid diagrams
        entry: mmdc --validate
        language: node
        files: \.md$
```

**Pros**:
- Catches issues early
- Fast feedback
- Works offline
- Forces developers to think about docs

**Cons**:
- Can be bypassed with `--no-verify`
- Requires local setup
- Doesn't help with forgotten updates

---

## Recommended Implementation Plan

### Phase 1: Foundation (Week 1-2)

1. **Set up GitHub Actions workflows**
   - Create `.github/workflows/` directory structure
   - Implement static documentation generation
   - Add JavaDoc generation to CI/CD

2. **Establish documentation standards**
   - Expand `.github/instructions/documentation.instructions.md`
   - Define what needs to be documented when
   - Create templates for ADRs, guides

3. **Implement basic automation**
   ```yaml
   # .github/workflows/doc-check.yml
   name: Documentation Check
   
   on:
     pull_request:
       types: [opened, synchronize]
   
   jobs:
     check-docs:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         
         - name: Check for documentation updates
           run: |
             # Simple heuristic checks
             if git diff --name-only origin/${{ github.base_ref }} | grep -q "src/main/"; then
               if ! git diff --name-only origin/${{ github.base_ref }} | grep -q "doc/\|README"; then
                 echo "⚠️  Code changes detected without documentation updates"
                 echo "Consider updating relevant documentation"
                 exit 1
               fi
             fi
   ```

### Phase 2: AI Integration (Week 3-4)

1. **Script for AI analysis** (`scripts/generate_doc_updates.py`):
   ```python
   #!/usr/bin/env python3
   """
   Analyzes code changes and generates documentation update suggestions.
   Uses Claude API for intelligent analysis.
   """
   import os
   import json
   from anthropic import Anthropic
   
   def analyze_changes(changed_files, diffs):
       """Analyze code changes and suggest documentation updates."""
       client = Anthropic(api_key=os.environ['ANTHROPIC_API_KEY'])
       
       prompt = f"""
       Analyze these code changes and suggest documentation updates:
       
       Changed files: {json.dumps(changed_files, indent=2)}
       Diffs: {json.dumps(diffs, indent=2)}
       
       Consider:
       1. Does the architecture diagram in README.md need updates?
       2. Should we create a new ADR?
       3. Do any guides need updating?
       4. Are there new APIs that need documentation?
       5. Do test guidelines need updates?
       
       Provide specific, actionable suggestions in Markdown format.
       """
       
       response = client.messages.create(
           model="claude-3-5-sonnet-20241022",
           max_tokens=4096,
           messages=[{"role": "user", "content": prompt}]
       )
       
       return response.content[0].text
   
   if __name__ == "__main__":
       # Read diffs from environment or file
       diffs = json.loads(os.environ.get('DIFFS', '[]'))
       suggestions = analyze_changes([], diffs)
       
       with open('doc_updates.md', 'w') as f:
           f.write(suggestions)
   ```

2. **Set up GitHub Secrets**:
   - `ANTHROPIC_API_KEY` or `OPENAI_API_KEY`
   - Configure in GitHub Enterprise settings

3. **Create workflow** that uses the script

### Phase 3: Advanced Features (Week 5-6)

1. **Automated diagram updates**
   - Parse Java code to update Mermaid diagrams
   - Generate sequence diagrams from method calls
   - Update architecture diagrams automatically

2. **Documentation PR automation**
   - If changes are significant, create a separate documentation PR
   - Link it to the code PR
   - Assign to appropriate reviewers

3. **Continuous verification**
   - Check that code examples in docs actually work
   - Validate API documentation against actual endpoints
   - Test that configuration examples are valid

---

## Tool Recommendations

### AI/LLM Services
1. **Claude (Anthropic)** - Best for code analysis and documentation
2. **GPT-4** - Good alternative, widely supported
3. **GitHub Copilot Enterprise** - Native GitHub integration (if available)

### Documentation Tools
1. **Mermaid** - Diagrams in Markdown (already used)
2. **PlantUML** - More complex diagrams
3. **Swagger/OpenAPI** - API documentation
4. **JavaDoc** - Java API docs
5. **AsciiDoctor** - Advanced documentation formatting

### CI/CD Tools
1. **GitHub Actions** - Native, good for GitHub Enterprise
2. **Pre-commit** - Local validation
3. **Danger.js** - PR automation and checks
4. **Renovate Bot** - Dependency updates with changelog

### Diagram Generation
1. **javaparser** - Parse Java to generate diagrams
2. **archunit** - Architecture testing and documentation
3. **structurizr** - C4 model diagrams from code

---

## GitHub Enterprise Considerations

### Authentication & Permissions
- Use GitHub App tokens instead of personal access tokens
- Configure proper permissions for bot accounts
- Use GITHUB_TOKEN for workflow actions when possible

### Self-Hosted Runners
```yaml
jobs:
  doc-generation:
    runs-on: [self-hosted, linux, x64]  # Use internal runners
    steps:
      - name: Access internal resources
        run: |
          # Can access internal APIs, databases, etc.
```

### Security & Compliance
- **Code scanning**: Ensure AI doesn't leak sensitive code
- **Secrets management**: Use GitHub Secrets or HashiCorp Vault
- **Audit logging**: Track all automated documentation changes
- **Access control**: Limit which repos can use AI features

### Enterprise Features to Leverage
- **GitHub Advanced Security**: Scan generated docs
- **GitHub Copilot Enterprise**: Native AI integration
- **GitHub Apps**: Create custom documentation bots
- **API rate limits**: Higher limits for Enterprise
- **SSO/SAML**: Integrate with corporate identity

---

## Example Workflows for mgt-axiom-server

### Workflow 1: Documentation Reminder

```yaml
# .github/workflows/doc-reminder.yml
name: Documentation Reminder

on:
  pull_request:
    types: [opened, synchronize]
    paths:
      - 'src/main/java/**'

jobs:
  remind:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          
      - name: Check for doc updates
        uses: actions/github-script@v7
        with:
          script: |
            const { execSync } = require('child_process');
            
            // Get changed files
            const changedFiles = execSync(
              `git diff --name-only origin/${{ github.base_ref }}...HEAD`
            ).toString().split('\n');
            
            const codeChanged = changedFiles.some(f => 
              f.startsWith('src/main/java/')
            );
            const docChanged = changedFiles.some(f => 
              f.startsWith('doc/') || f.includes('README')
            );
            
            if (codeChanged && !docChanged) {
              await github.rest.issues.createComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: context.payload.pull_request.number,
                body: `## 📝 Documentation Update Reminder
                
                This PR modifies Java code but doesn't update documentation.
                
                Please consider updating:
                - [ ] README.md - if architecture or setup changed
                - [ ] doc/architecture.md - if system design changed
                - [ ] doc/adr/ - if significant decisions were made
                - [ ] doc/guideline/ - if best practices changed
                - [ ] JavaDoc comments - for public APIs
                
                If documentation updates aren't needed, please explain why in the PR description.`
              });
            }
```

### Workflow 2: Auto-Generate JavaDoc

```yaml
# .github/workflows/javadoc.yml
name: Generate JavaDoc

on:
  push:
    branches: [main]
    paths:
      - 'src/main/java/**'

jobs:
  javadoc:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          
      - name: Set up JDK 21
        uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'temurin'
          cache: 'maven'
          
      - name: Generate JavaDoc
        run: mvn javadoc:javadoc
        
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./target/site/apidocs
          destination_dir: javadoc
```

### Workflow 3: AI Documentation Suggestions

```yaml
# .github/workflows/ai-doc-suggestions.yml
name: AI Documentation Suggestions

on:
  pull_request:
    types: [opened, synchronize]
    paths:
      - 'src/**/*.java'

jobs:
  ai-suggest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          
      - name: Get PR diff
        id: diff
        run: |
          git diff origin/${{ github.base_ref }}...HEAD > pr_diff.txt
          
      - name: Analyze with AI
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          PR_TITLE: ${{ github.event.pull_request.title }}
          PR_BODY: ${{ github.event.pull_request.body }}
        run: |
          cat > analyze.py << 'SCRIPT'
          import os
          from anthropic import Anthropic
          
          client = Anthropic(api_key=os.environ['ANTHROPIC_API_KEY'])
          
          with open('pr_diff.txt') as f:
              diff = f.read()
          
          prompt = f"""
          PR Title: {os.environ['PR_TITLE']}
          PR Description: {os.environ['PR_BODY']}
          
          Diff:
          ```
          {diff[:4000]}  # Limit to avoid token limits
          ```
          
          Based on this Java code change, suggest specific documentation updates for:
          
          1. README.md architecture section - if architectural changes detected
          2. doc/adr/ - if this represents a significant design decision
          3. Relevant guides in doc/ - if feature behavior changed
          4. JavaDoc - if public API changed
          
          Be specific about what should be updated and why.
          Format as a GitHub comment with checkboxes.
          """
          
          response = client.messages.create(
              model="claude-3-5-sonnet-20241022",
              max_tokens=2048,
              messages=[{"role": "user", "content": prompt}]
          )
          
          with open('suggestions.md', 'w') as f:
              f.write(response.content[0].text)
          SCRIPT
          
          pip install anthropic
          python analyze.py
          
      - name: Post suggestions
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const suggestions = fs.readFileSync('suggestions.md', 'utf8');
            
            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.payload.pull_request.number,
              body: `## 🤖 AI-Generated Documentation Suggestions\n\n${suggestions}\n\n---\n*Generated by Claude - please review and adjust as needed*`
            });
```

---

## Cost Estimation

### AI API Costs (Monthly)
- **Claude API**: ~$50-200/month for active repo
- **GPT-4 API**: ~$75-250/month for active repo
- **GitHub Copilot Enterprise**: $39/user/month (includes this feature)

### Infrastructure Costs
- **GitHub Actions**: Free for public repos, included in Enterprise
- **Storage**: Minimal (documentation is small)
- **Bandwidth**: Negligible

### Time Savings
- **Manual doc updates**: 2-4 hours per major feature
- **With automation**: 15-30 minutes review
- **ROI**: Positive after ~10 PRs

---

## Risks & Mitigation

### Risk 1: AI Hallucinations
**Mitigation**: 
- Always require human review
- Use AI for suggestions, not automatic commits
- Implement validation checks

### Risk 2: Cost Overruns
**Mitigation**:
- Set API usage limits
- Cache AI responses
- Use AI only for significant changes (>100 lines)

### Risk 3: Security Concerns
**Mitigation**:
- Never send credentials or secrets to AI
- Use local models for sensitive code
- Implement code sanitization before AI analysis

### Risk 4: Documentation Quality
**Mitigation**:
- Maintain human review process
- Use AI as assistant, not replacement
- Keep style guides and templates

---

## Success Metrics

1. **Documentation Freshness**: % of code changes with corresponding doc updates
2. **Review Time**: Time spent reviewing documentation in PRs
3. **Documentation Bugs**: Issues filed about incorrect/outdated docs
4. **Adoption Rate**: % of developers using automated tools
5. **Quality Score**: Manual audit of generated documentation

---

## Next Steps

### Immediate Actions (This Week)
1. ✅ Review this investigation document
2. ⬜ Decide on approach (recommend Hybrid - Phase 1 + Phase 2)
3. ⬜ Set up GitHub Actions in mgt-axiom-server
4. ⬜ Implement Workflow 1 (Documentation Reminder)

### Short-term (Next 2 Weeks)
1. ⬜ Configure API keys in GitHub Secrets
2. ⬜ Implement Workflow 3 (AI Suggestions)
3. ⬜ Create `scripts/generate_doc_updates.py`
4. ⬜ Test on a few PRs

### Medium-term (Next Month)
1. ⬜ Roll out to all developers
2. ⬜ Gather feedback and iterate
3. ⬜ Implement Workflow 2 (JavaDoc generation)
4. ⬜ Add advanced features (diagram generation)

### Long-term (Next Quarter)
1. ⬜ Extend to other repositories
2. ⬜ Build custom GitHub App for documentation
3. ⬜ Integrate with corporate knowledge base
4. ⬜ Measure ROI and optimize

---

## References & Resources

### Documentation
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Apps Documentation](https://docs.github.com/en/apps)
- [Mermaid Documentation](https://mermaid.js.org/)
- [JavaDoc Guide](https://www.oracle.com/technical-resources/articles/java/javadoc-tool.html)

### AI/LLM APIs
- [Anthropic Claude API](https://docs.anthropic.com/claude/docs)
- [OpenAI API](https://platform.openai.com/docs)
- [GitHub Copilot Enterprise](https://docs.github.com/en/copilot)

### Tools
- [Danger.js](https://danger.systems/js/)
- [Pre-commit](https://pre-commit.com/)
- [PlantUML](https://plantuml.com/)
- [Swagger](https://swagger.io/)

### Best Practices
- [Documentation-Driven Development](https://gist.github.com/zsup/9434452)
- [The C4 Model](https://c4model.com/)
- [Architecture Decision Records](https://adr.github.io/)

---

## Appendix: Sample Scripts

### A. Check Documentation Sync Script

```bash
#!/bin/bash
# scripts/check_doc_sync.sh

set -e

echo "Checking documentation synchronization..."

# Get changed files
CHANGED_FILES=$(git diff --cached --name-only)

# Check if Java files changed
if echo "$CHANGED_FILES" | grep -q "src/main/java/"; then
  echo "✓ Java code changes detected"
  
  # Check if documentation also changed
  if echo "$CHANGED_FILES" | grep -q -E "doc/|README.md|.*\.md"; then
    echo "✓ Documentation updates detected"
  else
    echo "⚠️  Warning: Java code changed but no documentation updates"
    echo "Please consider updating:"
    echo "  - README.md (if architecture changed)"
    echo "  - doc/adr/ (if design decisions made)"
    echo "  - Relevant guides in doc/"
    echo ""
    echo "To skip this check, use: git commit --no-verify"
    exit 1
  fi
fi

echo "✓ Documentation check passed"
```

### B. Update README TOC Script

```bash
#!/bin/bash
# scripts/update_toc.sh

set -e

# Check if markdown-toc is installed
if ! command -v markdown-toc &> /dev/null; then
  echo "Installing markdown-toc..."
  npm install -g markdown-toc
fi

# Update TOC in README
echo "Updating README table of contents..."
markdown-toc -i README.md

# Stage the changes
git add README.md

echo "✓ TOC updated"
```

### C. Validate Mermaid Diagrams

```bash
#!/bin/bash
# scripts/validate_mermaid.sh

set -e

# Find all Markdown files with Mermaid diagrams
FILES=$(grep -r -l "```mermaid" *.md doc/**/*.md 2>/dev/null || true)

if [ -z "$FILES" ]; then
  echo "No Mermaid diagrams found"
  exit 0
fi

# Extract and validate each diagram
for FILE in $FILES; do
  echo "Validating Mermaid diagrams in: $FILE"
  
  # Extract mermaid blocks and validate syntax
  # This is a simplified version - production would be more robust
  awk '/```mermaid/,/```/' "$FILE" | grep -v '```' > /tmp/mermaid_temp.mmd
  
  if [ -s /tmp/mermaid_temp.mmd ]; then
    # Use mmdc (mermaid CLI) to validate
    mmdc -i /tmp/mermaid_temp.mmd -o /tmp/mermaid_test.svg
    echo "  ✓ Valid Mermaid syntax"
  fi
done

echo "✓ All Mermaid diagrams validated"
```

---

**End of Investigation Document**
