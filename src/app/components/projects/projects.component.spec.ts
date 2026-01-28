import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ProjectsComponent } from './projects.component';

describe('ProjectsComponent', () => {
  let component: ProjectsComponent;
  let fixture: ComponentFixture<ProjectsComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ProjectsComponent]
    }).compileComponents();

    fixture = TestBed.createComponent(ProjectsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should have section title', () => {
    expect(component.sectionTitle).toBe('Proyectos Destacados');
  });

  it('should have section subtitle', () => {
    expect(component.sectionSubtitle).toBeTruthy();
    expect(component.sectionSubtitle.length).toBeGreaterThan(0);
  });

  it('should have 3 projects', () => {
    expect(component.projects.length).toBe(3);
  });

  it('should have projects with required properties', () => {
    component.projects.forEach(project => {
      expect(project.title).toBeTruthy();
      expect(project.category).toBeTruthy();
      expect(project.description).toBeTruthy();
      expect(project.image).toBeTruthy();
    });
  });

  it('should render section title in template', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h2')?.textContent).toContain(component.sectionTitle);
  });

  it('should render all project cards', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    const cards = compiled.querySelectorAll('.grid > div');
    expect(cards.length).toBe(3);
  });

  it('should render project titles', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    const titles = compiled.querySelectorAll('h3');
    expect(titles.length).toBe(3);
  });

  it('should have view all projects button', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.textContent).toContain('Ver todos los proyectos');
  });
});
