# Contributing to Daily Success Tracker

Thank you for considering contributing to Daily Success Tracker! We welcome contributions from the community.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Guidelines](#coding-guidelines)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Testing](#testing)

## 📜 Code of Conduct

This project and everyone participating in it is governed by a Code of Conduct. By participating, you are expected to uphold this code. Please be respectful and constructive in all interactions.

## 🤝 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected behavior** vs actual behavior
- **Screenshots** if applicable
- **Device/OS information**
- **App version** (found in settings)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title and description**
- **Use case** - why is this enhancement needed?
- **Proposed solution** or implementation ideas
- **Mockups or wireframes** if applicable

### Your First Code Contribution

Unsure where to begin? Look for issues labeled:
- `good first issue` - Simple issues for newcomers
- `help wanted` - Issues where we'd appreciate help
- `bug` - Known bugs that need fixing

## 🛠️ Development Setup

### Prerequisites

- Flutter SDK 3.6.1 or higher
- Dart SDK
- Android Studio or VS Code
- Git

### Setup Steps

1. **Fork the repository**
   ```bash
   # Click the Fork button on GitHub
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/Health-Tracker.git
   cd daily_success_tracker_1
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/PiyushPokharana/Health-Tracker.git
   ```

4. **Install dependencies**
   ```bash
   flutter pub get
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

### Project Structure

```
lib/
├── main.dart                 # App entry & themes
├── models/                   # Data models & DB
├── providers/                # State management
├── screens/                  # UI screens
├── widgets/                  # Reusable components
└── services/                 # Business logic
```

## 📝 Coding Guidelines

### Flutter/Dart Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` to check for issues
- Run `dart format .` before committing

### Code Quality

- **DRY Principle**: Don't Repeat Yourself
- **SOLID Principles**: Especially Single Responsibility
- **Meaningful Names**: Use descriptive variable/function names
- **Comments**: Explain *why*, not *what*
- **Error Handling**: Handle errors gracefully

### UI/UX Guidelines

- **Material Design 3**: Follow Material guidelines
- **Accessibility**: Ensure features are accessible
  - Add semantic labels
  - Maintain 48dp touch targets
  - Test with screen readers
  - Ensure good color contrast
- **Responsive**: Test on different screen sizes
- **Dark Mode**: Ensure visibility in both themes

### Design System

Maintain consistency with the existing design:

**Colors:**
```dart
Navy Blue:        #001F3F  (Primary)
Gold:             #D4AF37  (Accent)
Emerald Green:    #50C878  (Success)
Platinum Silver:  #E5E4E2  (Backgrounds)
```

**Typography:**
- Font family: Inter (via google_fonts)
- Maintain Material Design type scale

**Icons:**
- Use Material Icons only
- Avoid emoji in UI elements

## 💬 Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```bash
feat(backup): add export functionality
fix(dark-mode): improve button visibility
docs(readme): update installation instructions
style(home): format code with dart format
refactor(database): optimize query performance
test(habits): add unit tests for habit manager
chore(deps): update dependencies
```

## 🔄 Pull Request Process

### Before Submitting

1. **Update from upstream**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run tests**
   ```bash
   flutter test
   ```

3. **Check for issues**
   ```bash
   flutter analyze
   ```

4. **Format code**
   ```bash
   dart format .
   ```

5. **Test accessibility**
   - Run with TalkBack/VoiceOver
   - Check color contrast
   - Verify touch targets

### Submitting

1. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```

2. **Make your changes**
   - Write clean, documented code
   - Follow coding guidelines
   - Add tests if applicable

3. **Commit your changes**
   ```bash
   git commit -m "feat(scope): add amazing feature"
   ```

4. **Push to your fork**
   ```bash
   git push origin feature/amazing-feature
   ```

5. **Open a Pull Request**
   - Use a clear title and description
   - Reference related issues
   - Add screenshots/videos if UI changes
   - Explain what changed and why

### PR Review Process

- Maintainers will review your PR
- Address any requested changes
- Once approved, your PR will be merged
- Your contribution will be credited!

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/habit_test.dart

# Run with coverage
flutter test --coverage
```

### Test Guidelines

- Write tests for new features
- Maintain or improve code coverage
- Test edge cases and error scenarios
- Use meaningful test descriptions

### Manual Testing

Before submitting, manually test:
- [ ] Feature works as expected
- [ ] No regression in existing features
- [ ] Works on both Android and iOS
- [ ] Light and dark themes work
- [ ] Screen reader compatibility
- [ ] Different screen sizes/orientations

## 📚 Resources

### Flutter
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

### Design
- [Material Design 3](https://m3.material.io/)
- [Flutter Material Components](https://docs.flutter.dev/ui/widgets/material)

### Accessibility
- [Flutter Accessibility](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [WCAG Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

## ❓ Questions?

- Open an issue for questions
- Check existing issues and documentation
- Be patient and respectful

## 🎉 Recognition

Contributors will be:
- Listed in the GitHub contributors page
- Credited in release notes for significant contributions
- Part of an awesome open-source project!

Thank you for contributing! 🙏

---

**Happy Coding!** 🚀
