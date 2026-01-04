FROM swift:6.2.3

# Set CC for Bazel (clang is included in Swift image)
ENV CC=clang

WORKDIR /workspace

CMD ["/bin/bash"]
