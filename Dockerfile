FROM registry.gitlab.com/ordomatics/clients/ordomatics:latest

USER root

# System dependency for OCR (pytesseract shells out to the tesseract
# binary). tesseract-ocr-fra: French-language OCR data, needed for the
# French administrative-form target of smartacus_editor's scan feature
# (PV Gendarmerie, Lettre Administrative, ...). fonts-dejavu-core: covers
# Latin Extended (é, è, ê, ç, à) for redrawing replacement text on scans.
RUN apt-get update && apt-get install -y --no-install-recommends \
      tesseract-ocr tesseract-ocr-fra fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

# Install client-specific Python packages
COPY ./requirements.txt /tmp/client-requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=secret,id=github_token \
    GITHUB_TOKEN=$(cat /run/secrets/github_token 2>/dev/null || true) && \
    git config --global url."https://x-access-token:${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/" && \
    pip3 install --break-system-packages -r /tmp/client-requirements.txt && \
    (git config --global --unset url."https://x-access-token:${GITHUB_TOKEN}@github.com/".insteadOf || true)

# Copy client-specific addons and module list
COPY --chown=odoo:odoo ./addons /mnt/extra-addons
COPY ./modules.cfg /tmp/modules.cfg
