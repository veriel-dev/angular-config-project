import { Component } from '@angular/core';

interface Service {
  icon: string;
  title: string;
  description: string;
}

@Component({
  selector: 'app-services',
  templateUrl: './services.component.html'
})
export class ServicesComponent {
  sectionTitle = 'Nuestros Servicios';
  sectionSubtitle = 'Ofrecemos soluciones integrales para llevar tu negocio al siguiente nivel digital.';

  services: Service[] = [
    {
      icon: 'design',
      title: 'Diseno Web',
      description: 'Creamos interfaces atractivas y funcionales que cautivan a tus usuarios y reflejan la esencia de tu marca.'
    },
    {
      icon: 'development',
      title: 'Desarrollo Web',
      description: 'Construimos aplicaciones web robustas y escalables utilizando las tecnologias mas modernas del mercado.'
    },
    {
      icon: 'mobile',
      title: 'Apps Moviles',
      description: 'Desarrollamos aplicaciones nativas e hibridas que ofrecen experiencias excepcionales en cualquier dispositivo.'
    },
    {
      icon: 'consulting',
      title: 'Consultoria Digital',
      description: 'Te asesoramos en la transformacion digital de tu negocio con estrategias personalizadas y efectivas.'
    }
  ];
}
