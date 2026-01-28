import { Component } from '@angular/core';

interface Project {
  title: string;
  category: string;
  description: string;
  image: string;
}

@Component({
  selector: 'app-projects',
  templateUrl: './projects.component.html'
})
export class ProjectsComponent {
  sectionTitle = 'Proyectos Destacados';
  sectionSubtitle = 'Descubre algunos de los trabajos que hemos realizado para nuestros clientes.';

  projects: Project[] = [
    {
      title: 'E-commerce Premium',
      category: 'Desarrollo Web',
      description: 'Plataforma de comercio electronico con mas de 10,000 productos y pasarela de pago integrada.',
      image: 'ecommerce'
    },
    {
      title: 'App Fintech',
      category: 'Aplicacion Movil',
      description: 'Aplicacion de gestion financiera personal con integracion bancaria y analisis de gastos.',
      image: 'fintech'
    },
    {
      title: 'Portal Corporativo',
      category: 'Diseno Web',
      description: 'Rediseno completo de la presencia digital de una empresa Fortune 500.',
      image: 'corporate'
    }
  ];
}
