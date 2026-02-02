import sys
import pygame
from settings import Settings


def run_game():
    pygame.init()
    ai_setting = Settings()
    screen = pygame.display.set_mode(
        (ai_setting.screen_width, ai_setting.screen_height)
    )

    pygame.display.set_caption("Alien_Invasion")

    while True:
        screen.fill(ai_setting.bg_color)
        for even in pygame.event.get():
            if even.type == pygame.QUIT:
                sys.exit()

        pygame.display.flip()


run_game()
