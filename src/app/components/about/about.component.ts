import { Component } from '@angular/core';

interface Stat {
  value: string;
  label: string;
}

@Component({
  selector: 'app-about',
  templateUrl: './about.component.html'
})
export class AboutComponent {
  sectionTitle = 'Sobre Nosotros';
  description = 'Somos un equipo apasionado de disenadores y desarrolladores comprometidos con la excelencia. Desde 2015, hemos ayudado a empresas de todos los tamanos a alcanzar sus objetivos digitales.';
  secondaryText = 'Nuestra filosofia se basa en la colaboracion estrecha con nuestros clientes, entendiendo sus necesidades y superando sus expectativas en cada proyecto.';

  stats: Stat[] = [
    { value: '8+', label: 'Anos de experiencia' },
    { value: '150+', label: 'Proyectos completados' },
    { value: '50+', label: 'Clientes satisfechos' },
    { value: '15', label: 'Expertos en el equipo' }
  ];
}
