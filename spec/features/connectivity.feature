Feature:
  As a developer
  I want rabbit feed to connect to the message bus
  So that I can publish messages

Scenario: I can connect to the message bus
  Given I create a connection
  Then the connection is open
  When I close the connection
  Then the connection is closed

Scenario: I can publish a message
  Given I create a producer connection
  Then I can publish a message
