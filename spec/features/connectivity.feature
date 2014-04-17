Feature:
  As a developer
  I want rabbit feed to connect to the message bus
  So that I can publish and consume messages

Scenario: I can connect to the message bus
  When I create a connection
  Then the connection is open
  When I close the connection
  Then the connection is closed

Scenario: I can publish a message
  When I create a producer connection
  Then I can publish a message

Scenario: I can create an exchange
   When I declare a new exchange
    And I create a producer connection
   Then the exchange is created
    And I can publish a message
