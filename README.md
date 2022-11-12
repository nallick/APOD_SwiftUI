# APOD_SwiftUI

APOD_SwiftUI is a testbed for HTTP networking in Swift. Functionally, it uses NASA's public Astronomy Picture of the Day API (see APOD at api.nasa.gov) to display information about the picture of the day, accompanied by any still images. As a testbed, it's currently used primarily to explore background downloads, and methods to create unit tests for networking functions, using both Combine and Swift concurrency.

### Background Networking

BaseNetwork.URLLoader provides a URL session delegate to monitor network operations in progress and manages URL session task identifiers throughout the life of a network operation. In particular with background network operations, these task identifiers potentially persist beyond the application lifecycle. When the application is next launched, it can reanimate any outstanding background tasks and the operating system will update the application on their statuses. However, that reanimation isn't included in APOD_SwiftUI. It's left as an exercise for the reader.

URLLoader supports network operations through a delegate, Combine publishers, or by awaiting a Swift concurrency task. APOD_SwiftUI performs all its network operations using URLSession indirectly via URLLoader. Typically, picture metadata is requested through an ephemeral session, and any image is then downloaded with a background session.

### Unit Testing

APOD_SwiftUI experiments with several techniques for unit testing asynchronous network operations, using both Combine publishers and Swift concurrency tasks.

- APOD API calls are divided into two parts. First, a URLRequest object is created for the desired API call, then that request object is used to call the API. This pattern clearly separates the testing of API request formatting from the testing of API response handling.
- BaseSwiftMocks.URLProtocolMock provides a method for mocking network activity directly within URLSession via its support for custom network protocols. Tests can inject a custom URLRequest handler into a real URLSession object, thus tracking network requests and providing test responses without actually hitting the network.
- URLSession is extended to conform to the DataPublisherProvider and AsyncDataLoader protocols. This allows tests of API calls to provide mock Combine publishers and Swift concurrency data results, rather than using URLSession directly.
- XCTestCase is extended to allow tests to easily wait for Combine publisher results without complex boilerplate.

### License

APOD_SwiftUI is provided under the MIT license. See the LICENSE file for more info.
