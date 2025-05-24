# Birthday App

A Flutter web application for birthday countdowns, deployed on GitHub Pages.

## 🎉 Live Demo

Visit the live app at: `https://[your-username].github.io/birthday_app/`

## 🚀 Features

- Birthday countdown functionality
- Responsive web design
- Progressive Web App (PWA) support
- Automatic deployment to GitHub Pages

## 📱 Development

This project is built with Flutter and supports web deployment.

### Prerequisites

- Flutter SDK (3.24.0 or later)
- Dart SDK
- Web browser for testing

### Local Development

1. Clone the repository:
```bash
git clone https://github.com/[your-username]/birthday_app.git
cd birthday_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app locally:
```bash
flutter run -d web-server --web-port 8080
```

4. Open your browser and navigate to `http://localhost:8080`

### Building for Production

To build the web version:
```bash
flutter build web --base-href "/birthday_app/"
```

## 🔧 GitHub Pages Deployment

This project is configured for automatic deployment to GitHub Pages using GitHub Actions.

### Setup Instructions

1. **Push your code to GitHub:**
```bash
git add .
git commit -m "Initial commit with GitHub Pages integration"
git push origin main
```

2. **Enable GitHub Pages:**
   - Go to your repository on GitHub
   - Navigate to Settings → Pages
   - Under "Source", select "GitHub Actions"
   - The workflow will automatically trigger on the next push

3. **Access your deployed app:**
   - Your app will be available at `https://[your-username].github.io/birthday_app/`
   - The deployment typically takes 2-3 minutes

### Automatic Deployment

The GitHub Actions workflow (`.github/workflows/deploy.yml`) automatically:
- Builds the Flutter web app
- Deploys to GitHub Pages
- Triggers on every push to the `main` branch

## 📁 Project Structure

```
birthday_app/
├── .github/workflows/
│   └── deploy.yml          # GitHub Actions workflow
├── lib/
│   └── main.dart          # Main Flutter application
├── web/
│   ├── index.html         # Web entry point
│   ├── manifest.json      # PWA manifest
│   └── icons/             # App icons
├── pubspec.yaml           # Flutter dependencies
└── README.md              # This file
```

## 🛠️ Customization

To customize the app for your needs:

1. **Update app title and description:**
   - Edit `lib/main.dart` for the app title
   - Update `web/manifest.json` for PWA metadata
   - Modify `web/index.html` for page title and description

2. **Change app icons:**
   - Replace icons in `web/icons/` directory
   - Update `web/manifest.json` if needed

3. **Modify the base href:**
   - If deploying to a different repository name, update the `--base-href` in `.github/workflows/deploy.yml`

## 📝 License

This project is open source and available under the [MIT License](LICENSE).
