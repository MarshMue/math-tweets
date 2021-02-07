FROM debian
WORKDIR /

USER root
EXPOSE 8888

ENV CONDA_DIR=/opt/conda
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH=${CONDA_DIR}/bin:${PATH}

ARG JULIA_VER=1.5.3
ARG JULIA_URL=https://julialang-s3.julialang.org/bin/linux/aarch64/1.5

# Install just enough for conda and julia to work (libxt6 -to- libqt5widgtets5 are for Plots.jl)
RUN apt-get update > /dev/null && \
    apt-get install --no-install-recommends --yes \
        wget bzip2 ca-certificates \
        git libxt6 libxrender1 \
        libxext6 libgl1-mesa-glx \
        libqt5widgets5 > /dev/null && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install miniconda
RUN wget --quiet https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh && \
    bash Miniforge3-Linux-aarch64.sh -b -p ${CONDA_DIR} && \
    rm Miniforge3-Linux-aarch64.sh && \
    conda clean -tipsy && \
    find ${CONDA_DIR} -follow -type f -name '*.a' -delete && \
    find ${CONDA_DIR} -follow -type f -name '*.pyc' -delete && \
    conda clean -afy

RUN ln -s ${CONDA_DIR}/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo "source ${CONDA_DIR}/etc/profile.d/conda.sh" >> /etc/bash.bashrc && \
    echo "conda activate base" >> /etc/bash.bashrc

# Install Jupyter
RUN conda update -y conda && \
	conda install -y -c conda-forge jupyterlab

# install julia
RUN wget --quiet ${JULIA_URL}/julia-${JULIA_VER}-linux-aarch64.tar.gz && \
    tar -xf julia-${JULIA_VER}-linux-aarch64.tar.gz && \
	rm -rf julia-${JULIA_VER}-linux-aarch64.tar.gz && \
	ln -s /julia-${JULIA_VER}/bin/julia /usr/local/bin/julia 

# install julia packages
COPY package_install.jl tmp/package_install.jl
RUN julia tmp/package_install.jl

# setup workspace
WORKDIR /usr/src/
COPY src/ ./

# start jupyter lab
CMD [ "jupyter", "lab", "--ip='0.0.0.0'", "--allow-root", "--no-browser" ]
