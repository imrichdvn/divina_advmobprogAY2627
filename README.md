# Bulldogs Exchange

Bulldogs Exchange is a Flutter e-commerce application created for **Lab Activity 3 - API Part II**. It displays the complete DummyJSON product catalog and demonstrates cart retrieval, cart creation, shared product details, quantity management, navigation, and theme switching.

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

## Project Structure

```text
lib/
|-- models/
|   |-- cart.dart
|   `-- product.dart
|-- providers/
|   `-- theme_provider.dart
|-- screens/
|   |-- cart_screen.dart
|   |-- detail_screen.dart
|   |-- home_screen.dart
|   |-- product_screen.dart
|   `-- settings_screen.dart
|-- services/
|   |-- cart_service.dart
|   `-- product_service.dart
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
| Complete product catalog | `GET` | `/products?limit=0` |
| Single product | `GET` | `/products/{productId}` |
| All carts | `GET` | `/carts` |
| Cart by ID | `GET` | `/carts/{cartId}` |
| Carts by user ID | `GET` | `/carts/user/{userId}` |
| Add a cart | `POST` | `/carts/add` |

The activity uses demo user ID `1`. DummyJSON simulates cart creation and returns the newly constructed cart, but it does not permanently save POST requests. The returned cart is therefore retained in the application's local state for the current session.

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
