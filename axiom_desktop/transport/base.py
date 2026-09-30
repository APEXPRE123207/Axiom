"""
Abstract Base Class for Axiom Transport Servers.
"""
from abc import ABC, abstractmethod
from typing import Callable, Any, Dict

class ITransportServer(ABC):
    @abstractmethod
    def start(self, on_event: Callable[[Dict[str, Any], Any], None]):
        """Starts listening for incoming client connections."""
        pass

    @abstractmethod
    def stop(self):
        """Stops the transport server."""
        pass

    @abstractmethod
    def send_to_client(self, client_handle: Any, packet: Dict[str, Any]):
        """Sends an event packet back to a specific connected client."""
        pass
