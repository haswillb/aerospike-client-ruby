FROM ruby:latest

ADD . .

RUN bundle install && \
    rake build && \
    rake install

CMD ["./tests.sh"]

