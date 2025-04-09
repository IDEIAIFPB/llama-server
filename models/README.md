# Models

This folder is where you should place your LLM model files (e.g., GGUF models) for use with the Llama server.

## Usage

- **Model Files:** Copy your model files into this directory. Examples might include files like `gemma-3-12b-it-q4_0_s.gguf` or others relevant to your use case.
- **Mounting:** This directory is mounted as a volume into the container at `/models`. The server configuration (in `/app/config.yaml`) should reference this location for loading models.
- **Storage:** Ensure there is sufficient storage in this directory, as model files can be large.

## Notes

- **Permissions:** Ensure that the models have appropriate permissions so that Docker can read them.
- **Updates:** You can add, update, or remove models here without rebuilding the entire container.
- **Backup:** Consider backing up your model files separately if they are critical to your workflow.

For further instructions, consult the main [README](../README.md) in the project root.