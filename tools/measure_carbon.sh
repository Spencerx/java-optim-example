#!/bin/bash

# Initialize SDKman 
source "/home/ubuntu/.sdkman/bin/sdkman-init.sh"


# Force reload SDKman in case it's not in PATH
source "$HOME/.sdkman/bin/sdkman-init.sh" 2>/dev/null || true

# Install codecarbon if not already installed
if ! python3 -c "import codecarbon" 2>/dev/null; then
    echo "Installing codecarbon..."
    pip install codecarbon
fi

sdk use java 8.0.422-tem
java -version

# Create results directory if it doesn't exist
mkdir -p /workspace/results

cd /workspace/target
mvn install -Dmaven.compiler.debug=true

# Run the carbon measurement script
python3 /workspace/tools/measure_carbon.py