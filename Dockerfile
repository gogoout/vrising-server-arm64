# Use Ubuntu 22.04 as base
FROM ubuntu:jammy
VOLUME ["/vrising/server", "/vrising/data", "/home/steam/steamcmd"]

# Install cURL, Python 3, sudo, unbuffer and the package for "add-apt-repository"
RUN apt update -y && apt install -y curl wget python3 sudo expect-dev software-properties-common xvfb


# Download Install FEX script to temp file
RUN curl --silent https://raw.githubusercontent.com/FEX-Emu/FEX/main/Scripts/InstallFEX.py --output /tmp/InstallFEX.py

# FEX installer has to install RootFS on the user we want to run the program
# Run as steam user, auto answer yes for all prompts and auto extract on "FEXRootFSFetcher"
# also makes it run with unbuffer because it's fucking shit (TLDR wants to run under zenity when we don't have a display, isatty call being stupid)
RUN sed -i 's@\["FEXRootFSFetcher"\]@"sudo -u root bash -c \\"unbuffer FEXRootFSFetcher -y -x\\"", shell=True@g' /tmp/InstallFEX.py

# Run verification on steam user
RUN sed -i 's@\["FEXInterpreter", "/usr/bin/uname", "-a"\]@"sudo -u root bash -c \\"FEXInterpreter /usr/bin/uname -a\\"", shell=True@g' /tmp/InstallFEX.py

# Run Install FEX and remove the temp file
RUN python3 /tmp/InstallFEX.py && rm /tmp/InstallFEX.py


ENV WINE_VERSION 9.8
ENV WINE_BRANCH devel

# Install wine, wine64, and winetricks
COPY install-wine.sh /
RUN bash /install-wine.sh \
 && rm /install-wine.sh
 
# Install box wrapper for wine
COPY wrap-wine.sh /
RUN bash /wrap-wine.sh \
&& rm /wrap-wine.sh
 

# Download and extract SteamCMD
WORKDIR /home/steam/steamcmd
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
RUN chmod -R 777 /home/steam/steamcmd

WORKDIR /home/steam

# Copy init-server.sh to container
COPY --chmod=777 ./init-server.sh .

# Copy the health check script
COPY --chmod=777 ./healthz.sh .

# Define the health check
HEALTHCHECK --interval=10s --timeout=5s --retries=3 --start-period=8m \
    CMD /home/steam/healthz.sh

# Run it
CMD ["./init-server.sh"] 