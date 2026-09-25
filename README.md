# Bulldogs Exchange

Bulldogs Exchange is a Flutter e-commerce application built with DummyJSON. It includes the product catalog and cart from **Lab Activity 3 - API Part II**, plus persistent sign-in and a user profile from **Lab Activity 4 - API Part III**.

## Features

- Displays all products from DummyJSON using `limit=0`.
- Searches products by title, category, or brand.
- Opens a reusable product detail screen from the catalog or cart.
- Loads one cart using a DummyJSON user ID.
- Adds catalog products through the `/carts/add` endpoint.
- Increases and decreases cart quantities with automatic total recalculation.
- Removes an item when Minus is pressed while its quantity is `1`.
- Provides Home, Cart, and Profile bottom-navigation destinations.
- Shows Chat as a floating action button on Home and Profile.
- Hides the Chat button while the Cart screen is selected.
- Displays the Bulldogs Exchange logo in the Home header and Profile screen.
- Supports light and dark themes from the Settings screen.
- Signs in through the DummyJSON authentication endpoint.
- Restores the saved user profile on launch and clears it on sign-out.
- Displays the signed-in user's name, avatar, email, and account details.
- Provides interactive like and comment controls on profile update placeholders.
- Loads and creates carts using the signed-in user's ID.

## Project Structure

```text
lib/
|-- models/
|   |-- cart.dart
|   |-- product.dart
|   `-- user.dart
|-- providers/
|   `-- theme_provider.dart
|-- screens/
|   |-- cart_screen.dart
|   |-- detail_screen.dart
|   |-- home_screen.dart
|   |-- product_screen.dart
|   |-- profile_screen.dart
|   |-- sign_in_screen.dart
|   |-- splash_screen.dart
|   `-- settings_screen.dart
|-- services/
|   |-- cart_service.dart
|   |-- product_service.dart
|   `-- user_service.dart
|-- widgets/
|   `-- custom_text.dart
|-- constants.dart
`-- main.dart
```

## API Configuration

The API host is stored in `assets/.env`:

```env
API_HOST=https://dummyjson.com
```

The application communicates directly with DummyJSON and does not require a separate GitHub JSON repository.

### Endpoints Used

| Purpose | Method | Endpoint |
|---|---|---|
| Sign in | `POST` | `/auth/login` |
| Complete product catalog | `GET` | `/products?limit=0` |
| Single product | `GET` | `/products/{productId}` |
| All carts | `GET` | `/carts` |
| Cart by ID | `GET` | `/carts/{cartId}` |
| Carts by user ID | `GET` | `/carts/user/{userId}` |
| Add a cart | `POST` | `/carts/add` |

The user ID returned by `/auth/login` is passed to both cart retrieval and cart creation. DummyJSON simulates cart creation and returns the newly constructed cart, but it does not permanently save POST requests. The returned cart is retained in the application's memory for the current session.

## Lab Activity 3 Discussion

### Model, Service, and Screen Interaction

`Cart` and `CartProduct` define the cart data returned by DummyJSON. They also contain the local calculations needed when a quantity changes or an item is removed. `Product` represents catalog products.

`ProductService` and `CartService` are responsible for HTTP requests and JSON conversion. The services return model objects instead of exposing raw JSON to the user interface.

`ProductScreen` requests the complete product catalog from `ProductService`. When Add to Cart is pressed, it passes the selected product and current quantities to `CartService`. `CartScreen` requests the selected user's cart, renders its products, manages quantity controls, and sends updated cart values back to `HomeScreen`.

`HomeScreen` holds the current cart in memory. It shares that cart with the Product and Cart screens so the cart badge, contents, quantities, and totals remain synchronized.

### Shared Detail Screen

Both catalog products and cart products open `DetailScreen`. The screen provides constructors for `Product` and `CartProduct`, allowing the same interface to display data from either endpoint.

### Updated Design Pattern

The project follows a layered structure:

- **Models** define application data and local calculations.
- **Services** handle API requests and JSON parsing.
- **Screens** manage page state, navigation, and presentation.
- **Providers** manage shared theme state.
- **Widgets** contain reusable interface components.

This separation keeps networking out of the widgets, prevents models from depending on the UI, and makes the service and cart behavior easier to test.

### Getting Carts by ID and User ID

`CartService.getCartById(cartId)` requests `/carts/{cartId}` and returns one cart directly.

`CartService.getCartByUserId(userId)` requests `/carts/user/{userId}`. Because the response contains a `carts` array, the service parses the array and returns the first cart belonging to that user. If no cart exists, it returns an empty cart for the requested user.

### Enhancements

1. **Cart screen and shared details:** The application renders one user's cart. Every cart item is clickable and opens `DetailScreen`.
2. **Floating Chat button:** Chat is implemented as a floating action button on Home and Profile and is hidden on the Cart screen.
3. **User cart and Add to Cart:** The application loads a cart by user ID and sends product IDs and quantities to `https://dummyjson.com/carts/add`.

## Lab Activity 4 Discussion

### User Model, Service, and Screens

`UserService.loginUser` sends the username, password, and `expiresInMins: 60` to `POST /auth/login`. It parses the response into the `User` model and saves the profile fields and API tokens individually with `shared_preferences`. `SplashScreen` displays for 1.5 seconds, checks for a saved access token, and routes a returning user to `/home` with the saved user data; a new or signed-out user is routed to `/signin`.

After sign-in, `SignInScreen` passes the returned user data as the `/home` route argument. `HomeScreen` converts it to the authenticated `User` model and passes it to `ProfileScreen`. The profile renders the user's name, username, email, ID, gender, and remote avatar, with initials shown when the image is missing or unavailable. Its example update cards provide working like and comment controls. Signing out clears the saved preferences before returning to sign-in.

### Updated Design Pattern

The app uses a layered model-service-screen pattern. `User` maps API and locally saved profile data. `UserService` owns the authentication request, response parsing, and session persistence. `SplashScreen` and `SignInScreen` control session routing and form state; `HomeScreen` distributes the authenticated user; `ProfileScreen` renders it. These boundaries keep HTTP and preference operations out of the UI widgets.

### Cart for the Saved User

`HomeScreen` passes `user.id` to both `ProductScreen` and `CartScreen`. The cart screen requests `GET /carts/user/{userId}` through `CartService`; adding products and confirming an order use that same ID in the request body. This keeps cart data associated with the signed-in profile instead of a hard-coded demo account.

The password is never saved. Following the lab sample, the access and refresh tokens are saved in `shared_preferences`, and token presence is used to restore the demo session. Preferences are not encrypted secure storage, and the demo does not refresh or server-validate a restored token. A production service should use secure token storage and validate/refresh sessions with its backend.

### Demo Sign-In

DummyJSON provides demo users. For example, use username `emilys` and password `emilyspass` to test the sign-in flow. The API is a demonstration service and does not create real customer accounts.

## Cart Quantity Behavior

- Plus increases the selected product quantity by one.
- Minus decreases quantities greater than one.
- Pressing Minus at quantity one removes the product.
- Subtotal, discount, total products, and total quantity are recalculated after every change.

## Running the Application

```sh
flutter pub get
flutter run
```

## Verification

```sh
flutter analyze
flutter test
flutter build web
```

The final implementation passes static analysis, all automated tests, and a complete Flutter web build.
