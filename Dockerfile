FROM ruby:2.3.1

RUN apt-get update
RUN apt-get install -y \
  build-essential \
  libpq-dev imagemagick \
  libmagickwand-dev \
  libmagic-dev \
  libpq-dev \
  python-pygments \
  ghostscript

RUN apt-get install --no-install-recommends -y \
  texlive-latex-recommended

RUN apt-get install -y cron

ADD crontab /etc/cron.d/repopulate-df
RUN chmod 06444 /etc/cron.d/repopulate-df
CMD cron

ADD . /doubtfire-api
WORKDIR /doubtfire-api

EXPOSE 3000

RUN bundle install --without production test replica
RUN rake db:populate SCALE=large EXTENDED=true
