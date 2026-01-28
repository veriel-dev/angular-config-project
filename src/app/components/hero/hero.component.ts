import { Component } from '@angular/core';

@Component({
  selector: 'app-hero',
  templateUrl: './hero.component.html'
})
export class HeroComponent {
  headline = 'Transformamos ideas en experiencias digitales';
  subheadline = 'Somos una agencia de diseño y desarrollo web especializada en crear soluciones digitales que impulsan el crecimiento de tu negocio.';
  ctaText = 'Ver proyectos';
  ctaLink = '#projects';
  secondaryCtaText = 'Contactar';
  secondaryCtaLink = '#contact';
}
