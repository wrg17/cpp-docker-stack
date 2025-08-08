/**
 * @file server.cpp
 * @brief A basic c++ server with boost
 * 
 * @author Will George
 * @date 8/7/25
 * @version 0.1
 */

#include <boost/beast/core.hpp>
#include <boost/beast/http.hpp>
#include <boost/asio.hpp>
#include <iostream>

namespace   beast = boost::beast;
namespace   http  = beast::http;
namespace   asio  = boost::asio;

using       tcp   = asio::ip::tcp;

int main() {
  try {
    std::cout << std::nounitbuf;
    asio::io_context ioc{1};

    std::cout << "🚀 C++ Server starting...\n";

    constexpr asio::ip::port_type kPort = 8080;
    tcp::acceptor acceptor{ioc, {tcp::v4(), kPort}};
    std::cout << "Listening on http://localhost:" << kPort << "\n";

    for (uint32_t counter = 0;; counter++) {
      tcp::socket socket{ioc};
      acceptor.accept(socket);

      beast::flat_buffer buffer;
      http::request<http::string_body> req;
      http::read(socket, buffer, req);

      http::response<http::string_body> res{http::status::ok, req.version()};

      res.set(http::field::server, "Boost.Beast");
      res.set(http::field::content_type, "text/plain");

      res.body() = "Hello world! (#" + std::to_string(counter) + ")\n";
      res.prepare_payload();

      http::write(socket, res);
      socket.shutdown(tcp::socket::shutdown_send);

      std::cout << "Successful Response: " << counter << "\n";
    }
  } catch (std::exception const& e) {
    std::cerr << "Error: " << e.what() << '\n';
    return 1;
  }
}

