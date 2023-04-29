FROM python:3.9-buster
LABEL maintainer="Brandon Price <brandon@price.consulting>"

# Update and install ffmpeg
RUN apt-get update && \
    apt-get install -y ffmpeg 

# Copy and install requirements
COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
# reinstall yt-dlp from master because you need the latest version for the fs locking filesystem patch applied later to work
python3 -m pip install --force-reinstall https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz

# create abc user so root isn't used #using my convention of uid and gid 
RUN \
	groupmod -g 100 users && \
	useradd -u 1000 -U -d /config -s /bin/false abc && \
	usermod -G users abc && \
# create some files / folders
	mkdir -p /config /app /sonarr_root /logs && \
	touch /var/lock/sonarr_youtube.lock

# add volumes
VOLUME /config
VOLUME /sonarr_root
VOLUME /logs

# add local files
COPY app/ /app
COPY patches /patches

# patch non-blocking only filesystems for yt-dlp https://github.com/yt-dlp/yt-dlp/pull/6840/files 
RUN \
    cd /usr/local/lib/python3.9/site-packages/yt_dlp && \
    patch -p1 < /patches/yt_dlp_fs_locking.patch

# update file permissions
RUN \
    chmod a+x \
    /app/sonarr_youtubedl.py \ 
    /app/utils.py \
    /app/config.yml.template

# ENV setup
ENV CONFIGPATH /config/config.yml

CMD [ "python", "-u", "/app/sonarr_youtubedl.py" ]
