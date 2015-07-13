@connectivity
Feature:
  As a developer
  I want to be able to publish and consume events

Scenario: I can publish and consume events
  Given I am consuming
   When I publish an event
   Then I receive that event
   When I publish an event that cannot be processed by the consumer
   Then the event remains on the queue
