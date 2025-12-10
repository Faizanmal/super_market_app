# Contributing to SuperMart Pro

First off, thank you for considering contributing to SuperMart Pro! It's people like you that make SuperMart Pro such a great tool.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)
- [Testing](#testing)
- [Documentation](#documentation)

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to conduct@supermart.pro.

### Our Standards

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on what is best for the community
- Show empathy towards other community members

## Getting Started

### Prerequisites

**Backend:**
- Python 3.11+
- PostgreSQL 15+
- Redis 7+
- pip & virtualenv

**Frontend:**
- Flutter 3.16+
- Dart 3.2+
- Android Studio / Xcode (for mobile development)

### Development Setup

#### 1. Clone the Repository

```bash
git clone https://github.com/your-org/supermart-pro.git
cd supermart-pro
```

#### 2. Backend Setup

```bash
cd backend_super_market

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt  # Development dependencies

# Set up environment
cp .env.example .env
# Edit .env with your local settings

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Start development server
python manage.py runserver
```

#### 3. Frontend Setup

```bash
cd super_market_helper

# Get dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Run on device/emulator
flutter run
```

#### 4. Using Docker (Recommended)

```bash
# Start all services
docker-compose up -d

# Run migrations
docker-compose exec backend python manage.py migrate

# Create superuser
docker-compose exec backend python manage.py createsuperuser
```

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

1. **Clear Title**: Use a clear and descriptive title
2. **Steps to Reproduce**: Detailed steps to reproduce the issue
3. **Expected Behavior**: What you expected to happen
4. **Actual Behavior**: What actually happened
5. **Screenshots**: If applicable
6. **Environment Details**: OS, browser, versions, etc.

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

1. **Clear Title**: Use a clear and descriptive title
2. **Use Case**: Explain the use case for the feature
3. **Proposed Solution**: Describe the solution you'd like
4. **Alternatives**: Any alternative solutions you've considered

### Your First Code Contribution

Unsure where to begin? Look for issues labeled:

- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed
- `documentation` - Help improve docs

### Branch Naming Convention

- `feature/` - New features (e.g., `feature/bulk-import`)
- `fix/` - Bug fixes (e.g., `fix/login-redirect`)
- `docs/` - Documentation changes (e.g., `docs/api-reference`)
- `refactor/` - Code refactoring (e.g., `refactor/auth-service`)
- `test/` - Test additions (e.g., `test/product-api`)

## Pull Request Process

### Before Submitting

1. **Create an Issue**: Discuss major changes before implementation
2. **Branch from `develop`**: Create your feature branch from `develop`
3. **Write Tests**: Add tests for new functionality
4. **Update Documentation**: Update relevant documentation
5. **Follow Style Guidelines**: Ensure code follows our style guide

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature causing existing functionality to change)
- [ ] Documentation update

## Testing
Describe testing performed

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have performed a self-review
- [ ] I have commented my code where necessary
- [ ] I have updated documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests
- [ ] All tests pass locally
```

### Review Process

1. At least one maintainer must approve the PR
2. All CI checks must pass
3. No merge conflicts with `develop`
4. Code coverage must not decrease

## Style Guidelines

### Python (Backend)

We follow PEP 8 with some modifications:

```python
# Use type hints
def get_product(product_id: int) -> Product:
    ...

# Use docstrings
def calculate_reorder_point(product: Product) -> int:
    """
    Calculate the reorder point for a product.
    
    Args:
        product: The product to calculate for
        
    Returns:
        The recommended reorder point quantity
    """
    ...

# Class naming: PascalCase
class ProductService:
    ...

# Function naming: snake_case
def get_expiring_products():
    ...

# Constants: UPPER_SNAKE_CASE
MAX_BATCH_SIZE = 1000
```

**Tools:**
- `black` for formatting
- `isort` for import sorting
- `flake8` for linting
- `mypy` for type checking

```bash
# Run formatting
black .
isort .

# Run linting
flake8 .
mypy .
```

### Dart (Frontend)

We follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style):

```dart
// Use type annotations
Future<List<Product>> fetchProducts() async {
  ...
}

// Documentation comments
/// Fetches products from the API.
/// 
/// Returns a list of [Product] objects.
/// Throws [ApiException] if the request fails.
Future<List<Product>> fetchProducts() async {
  ...
}

// Class naming: PascalCase
class ProductRepository {
  ...
}

// Function/variable naming: camelCase
void loadProducts() {
  final productList = <Product>[];
}

// Constants: camelCase or SCREAMING_CAPS
const defaultPageSize = 20;
const API_TIMEOUT = Duration(seconds: 30);
```

**Tools:**
- `dart format` for formatting
- `dart analyze` for analysis

```bash
# Run formatting
dart format .

# Run analysis
flutter analyze
```

### Git Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**

```bash
feat(products): add bulk import functionality

- Add CSV import endpoint
- Add validation for imported data
- Add progress tracking for large imports

Closes #123
```

```bash
fix(auth): correct token refresh timing

The token was being refreshed too late, causing occasional
401 errors. This change refreshes the token 5 minutes before
expiration instead of 1 minute.

Fixes #456
```

## Testing

### Backend Tests

```bash
# Run all tests
python manage.py test

# Run specific test module
python manage.py test products.tests.test_views

# Run with coverage
coverage run manage.py test
coverage report -m
coverage html  # Generate HTML report
```

**Test Structure:**

```python
class ProductViewSetTestCase(APITestCase):
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(...)
        self.client.force_authenticate(user=self.user)

    def test_list_products_returns_200(self):
        """Test that listing products returns 200 OK."""
        response = self.client.get('/api/products/')
        self.assertEqual(response.status_code, 200)

    def test_create_product_with_valid_data(self):
        """Test creating a product with valid data."""
        data = {'name': 'Test Product', 'sku': 'TEST-001', ...}
        response = self.client.post('/api/products/', data)
        self.assertEqual(response.status_code, 201)
```

### Frontend Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/product_repository_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

**Test Structure:**

```dart
void main() {
  group('ProductRepository', () {
    late ProductRepository repository;
    late MockApiClient mockClient;

    setUp(() {
      mockClient = MockApiClient();
      repository = ProductRepository(client: mockClient);
    });

    test('fetchProducts returns list of products', () async {
      when(mockClient.get(any)).thenAnswer((_) async => mockResponse);
      
      final products = await repository.fetchProducts();
      
      expect(products, isA<List<Product>>());
      expect(products.length, 2);
    });
  });
}
```

## Documentation

### Code Documentation

- All public APIs must be documented
- Use docstrings (Python) and documentation comments (Dart)
- Include examples for complex functionality
- Keep documentation up-to-date with code changes

### README Updates

When adding features, update:
- Feature list in README
- Installation instructions if dependencies change
- Configuration options if new settings are added

### API Documentation

- Update OpenAPI/Swagger specs for API changes
- Include request/response examples
- Document error responses

---

## Questions?

Feel free to ask questions by:
- Opening a GitHub Discussion
- Asking in our Discord server
- Emailing dev@supermart.pro

Thank you for contributing! 🎉
