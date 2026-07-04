# Policies

## Data Integrity

NEVER create scripts, figures, or result files using synthetic, simulated, or randomly generated data as a substitute for real experimental results.

- DO NOT use `np.random`, `torch.rand`, `np.linspace()` or similar to generate fake scientific data
- DO NOT create visualizations based on summary statistics instead of raw data
- DO NOT reconstruct attribution patterns, gradients, or analysis results from partial information
- DO NOT generate placeholder data for any analysis or interpretability method
- DO NOT fabricate metadata: no invented PFAM descriptions, gene names, GO terms, or pathway annotations
- If annotation data is not in a local file or successfully retrieved from an API, state "annotation not available"

Acceptable: ML training operations (batch sampling, weight init, dropout), statistical bootstrapping of real data, clearly-marked synthetic test cases.

If real data is unavailable: stop and ask for it.

## Shell Commands

When writing multi-line shell commands for the user to copy-paste, EVERY line except the last MUST end with a backslash (`\`). The backslash must be the very last character on the line. Missing a single backslash on any non-final line will cause the terminal to execute a partial command.
