from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.image import Image
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.popup import Popup
from kivy.uix.textinput import TextInput
from kivy.core.window import Window
from kivy.metrics import dp
from kivy.uix.screenmanager import ScreenManager, Screen
from kivy.animation import Animation
from kivy.utils import get_color_from_hex
from kivy.clock import Clock
from kivy.properties import ListProperty, NumericProperty
import subprocess
import os

COLORS = {
    'background': '#000000',
    'text': '#00ff00',
    'accent': '#2b2b2b',
    'secondary': '#004000',
    'warning': '#ff0000'
}

class AnimatedImage(Image):
    rotation = NumericProperty(0)
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.opacity = 0
        # Initial entrance animation
        anim = Animation(opacity=1, duration=1.5) & Animation(rotation=360, duration=2)
        Clock.schedule_once(lambda dt: anim.start(self), 0.5)
        
        # Continuous floating animation
        self.float_animation()
        
    def float_animation(self, *args):
        anim = Animation(y=self.y + dp(10), duration=2) + Animation(y=self.y, duration=2)
        anim.bind(on_complete=self.float_animation)
        anim.start(self)

class HoverButton(Button):
    scale = NumericProperty(1)
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.background_normal = ''
        self.background_color = get_color_from_hex(COLORS['accent'])
        self.color = get_color_from_hex(COLORS['text'])
        self.font_size = '18sp'
        self.bold = True
        self.border = (2, 2, 2, 2)
        self.opacity = 0
        
    def on_enter(self, *args):
        Animation(scale=1.1, duration=0.2).start(self)
        self.background_color = get_color_from_hex(COLORS['secondary'])
        
    def on_leave(self, *args):
        Animation(scale=1, duration=0.2).start(self)
        self.background_color = get_color_from_hex(COLORS['accent'])
        
    def on_press(self):
        Animation(scale=0.95, duration=0.1).start(self)
        
    def on_release(self):
        Animation(scale=1, duration=0.1).start(self)

class CustomTextInput(TextInput):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.background_color = get_color_from_hex(COLORS['background'])
        self.foreground_color = get_color_from_hex(COLORS['text'])
        self.cursor_color = get_color_from_hex(COLORS['text'])
        self.font_size = '16sp'
        self.padding = [10, 10, 10, 10]
        self.multiline = False
        self.opacity = 0

class MainScreen(Screen):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.layout = FloatLayout()
        
        # Animated Logo
        self.logo = AnimatedImage(
            source='./img/banner.png',
            size_hint=(0.5, 0.5),
            pos_hint={'center_x': 0.5, 'center_y': 0.8}
        )
        self.layout.add_widget(self.logo)
        
        # Buttons with staggered entrance
        button_layout = BoxLayout(
            orientation='vertical',
            spacing=dp(20),
            size_hint=(0.8, 0.4),
            pos_hint={'center_x': 0.5, 'center_y': 0.4}
        )
        
        self.buttons = []
        button_texts = ['HELLO', 'HAPPY MODE', 'GIT CLONE']
        button_callbacks = [self.show_hello_popup, self.run_happy_mode, self.show_git_popup]
        
        for text, callback in zip(button_texts, button_callbacks):
            btn = HoverButton(text=text, size_hint=(1, None), height=dp(60))
            btn.bind(on_press=callback)
            self.buttons.append(btn)
            button_layout.add_widget(btn)
        
        self.layout.add_widget(button_layout)
        
        # Animated BYE button
        self.btn_bye = HoverButton(
            text='BYE',
            size_hint=(0.15, 0.08),
            pos_hint={'right': 0.98, 'bottom': 0.02},
            background_color=get_color_from_hex(COLORS['warning'])
        )
        self.btn_bye.bind(on_press=self.run_bye)
        self.layout.add_widget(self.btn_bye)
        
        # Animated Status bar
        self.status_bar = Label(
            text='Ready',
            size_hint=(1, None),
            height=dp(30),
            font_size='14sp',
            color=get_color_from_hex(COLORS['text']),
            pos_hint={'center_x': 0.5, 'y': 0.02},
            opacity=0
        )
        self.layout.add_widget(self.status_bar)
        self.add_widget(self.layout)
        
        # Schedule staggered entrance animations
        Clock.schedule_once(self.animate_entrance, 0.5)
        
    def animate_entrance(self, dt):
        # Animate buttons sequentially
        for i, btn in enumerate(self.buttons):
            anim = Animation(opacity=1, duration=0.5)
            anim &= Animation(pos_hint={'center_x': 0.5}, duration=0.5)
            Clock.schedule_once(lambda dt, b=btn: anim.start(b), i * 0.2)
        
        # Animate bye button
        bye_anim = Animation(opacity=1, duration=0.5)
        Clock.schedule_once(lambda dt: bye_anim.start(self.btn_bye), len(self.buttons) * 0.2)
        
        # Animate status bar
        status_anim = Animation(opacity=1, duration=0.5)
        Clock.schedule_once(lambda dt: status_anim.start(self.status_bar), (len(self.buttons) + 1) * 0.2)

    def show_popup(self, title, content):
        popup = Popup(
            title=title,
            content=content,
            size_hint=(0.8, None),
            height=dp(300),
            background_color=get_color_from_hex(COLORS['background']),
            title_color=get_color_from_hex(COLORS['text']),
            title_size='18sp',
            separator_color=get_color_from_hex(COLORS['accent'])
        )
        
        # Animate popup entrance
        popup.opacity = 0
        popup.scale = 0.8
        
        def on_open(*args):
            anim = Animation(opacity=1, duration=0.3) & Animation(scale=1, duration=0.3, t='out_back')
            anim.start(popup)
            
        popup.bind(on_open=on_open)
        return popup

    def show_hello_popup(self, instance):
        content = BoxLayout(orientation='vertical', spacing=dp(20), padding=dp(20))
        
        self.email_input = CustomTextInput(hint_text='GITHUB_EMAIL')
        self.user_input = CustomTextInput(hint_text='GITHUB_USERNAME')
        btn_submit = HoverButton(text='Submit', size_hint=(1, None), height=dp(50))
        btn_submit.bind(on_press=self.run_hello)
        
        for widget in [self.email_input, self.user_input, btn_submit]:
            content.add_widget(widget)
            
        self.popup = self.show_popup('Configure GitHub', content)
        self.popup.open()
        
        # Animate inputs and button sequentially
        for i, widget in enumerate([self.email_input, self.user_input, btn_submit]):
            anim = Animation(opacity=1, duration=0.3)
            Clock.schedule_once(lambda dt, w=widget: anim.start(w), i * 0.2)

    def update_status(self, message):
        self.status_bar.text = message
        anim = Animation(opacity=0, duration=0.3) + Animation(opacity=1, duration=0.3)
        anim.start(self.status_bar)

    def run_hello(self, instance):
        os.environ['GITHUB_EMAIL'] = self.email_input.text
        os.environ['GITHUB_USERNAME'] = self.user_input.text
        
        # Animate popup exit
        anim = Animation(opacity=0, scale=0.8, duration=0.3)
        anim.bind(on_complete=lambda *x: self.popup.dismiss())
        anim.start(self.popup)
        
        subprocess.run(['./jarvis.sh', 'hello'])
        self.update_status('Hello command executed')

    def run_happy_mode(self, instance):
        subprocess.Popen(['python3', './python_scripts/happy_jarvis.py'])
        self.update_status('Happy mode activated')

    def show_git_popup(self, instance):
        content = BoxLayout(orientation='vertical', spacing=dp(20), padding=dp(20))
        
        self.repo_input = CustomTextInput(hint_text='GITHUB_REPO SSH URL')
        btn_submit = HoverButton(text='Clone', size_hint=(1, None), height=dp(50))
        btn_submit.bind(on_press=self.run_git_clone)
        
        for widget in [self.repo_input, btn_submit]:
            content.add_widget(widget)
            
        self.popup = self.show_popup('Clone Repository', content)
        self.popup.open()
        
        # Animate inputs and button sequentially
        for i, widget in enumerate([self.repo_input, btn_submit]):
            anim = Animation(opacity=1, duration=0.3)
            Clock.schedule_once(lambda dt, w=widget: anim.start(w), i * 0.2)

    def run_git_clone(self, instance):
        repo = self.repo_input.text
        if repo:
            # Animate popup exit
            anim = Animation(opacity=0, scale=0.8, duration=0.3)
            anim.bind(on_complete=lambda *x: self.popup.dismiss())
            anim.start(self.popup)
            
            subprocess.run(['git', 'clone', repo])
            self.update_status(f'Cloned repository: {repo}')

    def run_bye(self, instance):
        # Animate all elements fade out
        for widget in self.layout.children:
            anim = Animation(opacity=0, duration=0.5)
            anim.start(widget)
            
        subprocess.run(['./jarvis.sh', 'bye'])
        self.update_status('Goodbye!')
        Clock.schedule_once(lambda dt: App.get_running_app().stop(), 2)

class JarvisApp(App):
    def build(self):
        Window.clearcolor = get_color_from_hex(COLORS['background'])
        self.title = 'JARVIS Controller'
        
        sm = ScreenManager()
        sm.add_widget(MainScreen(name='main'))
        
        return sm

if __name__ == '__main__':
    JarvisApp().run()