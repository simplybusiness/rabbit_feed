Feature:
  As a developer
  I want rabbit feed to connect to the message bus
  So that I can publish and consume messages

Scenario: I can connect to the message bus
  When I create a connection
  Then the connection is open
  When I close the connection
  Then the connection is closed

Scenario: I can create an exchange
   When I declare a new exchange
   Then the exchange is created
    And I can publish an event to the exchange

Scenario: I can create a queue
   When I declare a new queue
   Then the queue is created
    And the queue is bound to the exchange
    And I can consume an event from the queue

Scenario: When an event cannot be consumed it remains on the queue
   When I am unable to successfully process an event
   Then the event remains on the queue
