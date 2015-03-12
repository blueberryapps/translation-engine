# TranslationEngine

```
gem 'translation-engine', git: 'https://github.com/blueberryapps/translation-engine.git'


# Integration

## Screenshots

### Javascript
Require javascript by inserting `app/assets/javascripts/application.js`
//= require translation_engine/screenshots

Ensure that you have jquery + coffeescript
(or similar gems which provides same function)
```ruby
gem 'coffee-rails'
gem 'jquery-rails'
```

### Stylesheets
Require stylesheets by inserting `app/assets/stylesheets/application.sass`
@import translation_engine/screenshots

### Start translations
Create element with class `translation_engine_run`.
When you click on this element, Translation Engine will start screenshoting page
and then sends all images + highlights to server `/transaltion_engine` which
will be catched by `ScreenshotsMiddleware` and then send to TranslationServer.

or

Use callback by `window.TranslationEngine.start()`
