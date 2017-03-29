FROM swiftdocker/swift:3.1


WORKDIR /code

COPY Package.swift /code/
COPY ./Tests /code/Tests
COPY ./Sources /code/Sources

CMD swift test