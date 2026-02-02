import pygame
from settings import Settings
from ship import Ship
import game_function as gf


def run_game():
    pygame.init()
    ai_setting = Settings()
    screen = pygame.display.set_mode(
        (ai_setting.screen_width, ai_setting.screen_height)
    )

    pygame.display.set_caption("Alien_Invasion")
    ship = Ship(screen)

    while True:
        gf.check_events(ship)
        ship.update()
        gf.update_screen(ai_setting, screen, ship)

        pygame.display.flip()


run_game()
