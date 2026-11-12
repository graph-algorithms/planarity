"""Exercise color controls on real artists and rendered PNGs."""
import pytest


try:
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from matplotlib.collections import LineCollection, PatchCollection
    from matplotlib.colors import to_rgba
    TEST_ENV_HAS_MATPLOTLIB = True
except ImportError as matplotlib_import_error:
    TEST_ENV_HAS_MATPLOTLIB = False

try:
    from PIL import Image
    TEST_ENV_HAS_PILLOW = True
except ImportError as pillow_import_error:
    TEST_ENV_HAS_PILLOW = False

import planarity


@pytest.mark.skipif(
    not TEST_ENV_HAS_MATPLOTLIB,
    reason="matplotlib is not installed.",
)
@pytest.mark.skipif(
    not TEST_ENV_HAS_PILLOW,
    reason="pillow is not installed.",
)
class TestPlanarityExpressDraw:
    @pytest.fixture(autouse=True)
    def isolated_figures(self):
        with matplotlib.rc_context():
            yield
        plt.close('all')

    @pytest.fixture
    def edges(self):
        # Note the list of a fixture since this list is mutable.
        return [
            ('a', 'c'), ('a', 'd'), ('a', 'e'), ('b', 'c'), ('b', 'd'),
            ('b', 'e'), ('c', 'd'), ('c', 'e'), ('d', 'e'),
        ]

    @pytest.fixture(params=['function', 'method'])
    def draw(self, request, edges):
        if request.param == 'function':
            return lambda **kwargs: planarity.draw(edges, **kwargs)
        return lambda **kwargs: planarity.PGraph(edges).draw(**kwargs)

    @pytest.mark.parametrize('option,color', [
        ('facecolor', '#abcdef'),
        ('vertex_facecolor', 'gold'),
        ('vertex_bordercolor', (0.3, 0.2, 0.8)),
        ('vertex_label_facecolor', 'lightgreen'),
        ('vertex_label_bordercolor', '#aabbcc'),
        ('edge_linecolor', 'magenta'),
    ])
    def test_individual_colors_reach_artists(self, draw, option, color):
        draw(**{option: color})
        ax = plt.gca()
        if option == 'facecolor':
            actual = [plt.gcf().get_facecolor()]
        elif option.startswith('vertex_label_'):
            method = ('get_facecolor' if option.endswith('facecolor')
                    else 'get_edgecolor')
            actual = [getattr(text.get_bbox_patch(), method)() for text in ax.texts]
            assert len(actual) == 5
        elif option.startswith('vertex_'):
            vertices = next(
                c for c in ax.collections if isinstance(c, PatchCollection)
            )
            actual = (vertices.get_facecolors() if option.endswith('facecolor')
                    else vertices.get_edgecolors())
        else:
            actual = [c.get_colors()[0] for c in ax.collections
                    if isinstance(c, LineCollection)]
            assert len(actual) == 9
        assert len(actual) > 0
        for rgba in actual:
            assert tuple(rgba) == pytest.approx(to_rgba(color))

    @pytest.mark.parametrize('transparent', [False, True])
    def test_png_background_and_transparency(self, draw, tmp_path, transparent):
        output = tmp_path / 'colors.png'
        # A user's savefig style must not override an explicit draw() facecolor.
        matplotlib.rcParams['savefig.facecolor'] = 'red'
        draw(
            outfileName=str(output),
            figsize=(4, 3),
            dpi=100,
            facecolor='#abcdef',
            transparent=transparent,
        )
        with Image.open(output) as image:
            # The tight bounding box (Issue #100) crops the saved image to the
            # drawing plus pad_inches, so it is strictly smaller than the
            # nominal figsize canvas at the given dpi.
            width, height = image.size
            assert width == 400
            assert height == 300
            rgba = image.convert('RGBA')
            if transparent:
                assert rgba.getpixel((0, 0))[3] == 0
                assert rgba.getextrema()[3][1] == 255  # Graph remains visible.
            else:
                assert rgba.getpixel((0, 0)) == (171, 205, 239, 255)
        assert plt.gcf().get_facecolor() == pytest.approx(to_rgba('#abcdef'))

    def test_color_controls_combine_without_labels(self, draw, tmp_path):
        draw(
            outfileName=str(tmp_path / 'no-labels.png'),
            labels=False,
            facecolor='white',
            vertex_facecolor='yellow',
            vertex_bordercolor='black',
            vertex_label_facecolor='pink',
            vertex_label_bordercolor='green',
            edge_linecolor='red',
            transparent=True,
        )
        assert not plt.gca().texts
        vertices = next(
            c for c in plt.gca().collections if isinstance(c, PatchCollection)
        )
        assert (
            tuple(vertices.get_facecolors()[0]) ==
            pytest.approx(to_rgba('yellow'))
        )
        assert (
            tuple(vertices.get_edgecolors()[0]) ==
            pytest.approx(to_rgba('black'))
        )

    def test_default_background_resets_after_custom_draw(self, draw):
        draw(facecolor='red')
        draw()
        assert plt.gcf().get_facecolor() == pytest.approx(to_rgba('#ffffff'))
        for text in plt.gca().texts:
            assert text.get_bbox_patch().get_facecolor() == to_rgba('white')
            assert text.get_bbox_patch().get_edgecolor() == to_rgba('black')

    def test_existing_figure_options(self, draw):
        draw(figsize=(4, 3), dpi=120)
        assert tuple(plt.gcf().get_size_inches()) == pytest.approx((4, 3))
        assert plt.gcf().dpi == 120

    def test_unknown_keyword_still_rejected(self, draw):
        with pytest.raises(ValueError, match='not a supported draw'):
            draw(vertex_colour='red')

    def test_invalid_color_rejected(self, draw):
        with pytest.raises(ValueError, match='not-a-color'):
            draw(vertex_facecolor='not-a-color')

    def _background_run_length(self, image, start, step):
        """Walks from the start pixel in the step direction, counting how many
        background pixels are seen before the first non-background pixel.

        Fails the test if the walk reaches the far side of the image without
        meeting any ink, since then the padding is not being measured against
        the drawing at all.
        """
        # draw() also defaults the figure facecolor to white, and the padding it
        # leaves around the drawing has that same color, so a pixel counts as
        # background when each channel is close to white. The slack keeps the
        # anti-aliased pixels that blend background into ink from counting as ink.
        background = (255, 255, 255)
        background_slack = 8

        x, y = start
        run = 0
        while 0 <= x < image.width and 0 <= y < image.height:
            pixel = image.getpixel((x, y))
            if (
                max(abs(pixel[i] - background[i]) for i in range(3)) >
                background_slack
            ):
                return run
            run += 1
            x, y = x + step[0], y + step[1]
        raise AssertionError(
            f'walked from {start} across the image without finding the drawing'
        )

    def _assert_pad_inches(self, draw, tmp_path, pad_inches):
        # draw() defaults the figure dpi to 100, so pad_inches of padding shows
        # up in the saved image as pad_inches * 100 pixels of background on each
        # side.
        default_dpi = 100

        output = tmp_path / f'pad-{pad_inches}.png'
        # EDGES is K5 minus an edge, drawn here on the custom 4x3 figure. The
        # padding has to come out right on a caller-chosen figure size, not
        # only on the default one.
        draw(
            outfileName=str(output),
            figsize=(4, 3),
            pad_inches=pad_inches,
        )
        with Image.open(output) as saved:
            image = saved.convert('RGBA')
            width, height = image.size
            # The padding is only meaningful in pixels if the saved image really
            # is the requested figsize at the default dpi.
            assert (width, height) == (4 * default_dpi, 3 * default_dpi)

            expected = round(pad_inches * default_dpi)
            # From each starting point below, walk straight into the image and
            # expect expected pixels of background, then a pixel of the drawing.
            # Three sides start at the midpoints of the image edges. The right
            # side instead starts a quarter of the way down: the rightmost ink
            # in this drawing is a vertical edge line drawn a little to the
            # right of the rightmost vertices, and the line spans only part of
            # the image height. Below its lower end the rightmost ink is a
            # vertex box that ends slightly left of the line, so a walk there
            # would overcount the background. A quarter of the way down is
            # safely within the line at every pad_inches value used here.
            probes = [
                ('top', (width // 2, 0), (0, 1)),
                ('bottom', (width // 2, height - 1), (0, -1)),
                ('left', (0, height // 2), (1, 0)),
                ('right', (width - 1, height // 4), (-1, 0)),
            ]
            for side, start, step in probes:
                run = self._background_run_length(image, start, step)
                # The measured run can deviate from pad_inches * dpi by a pixel
                # or two: anti-aliasing blends the outermost drawing pixels
                # into the background, and when vertices are drawn with a
                # border (vertex_bordercolor) the border widens them, which
                # measured one pixel short of the expected run. Two pixels of
                # slack absorbs that, while still failing if the padding is off
                # by a whole step between the tested values (0.1 inch = 10
                # pixels at the default dpi).
                assert abs(run - expected) <= 2, (side, run, expected)

    def test_draw_pad_inches_controls_output_padding(self, draw, tmp_path):
        for pad_inches in (0.0, 0.1, 0.5):
            self._assert_pad_inches(draw, tmp_path, pad_inches)

    def test_draw_text(self):
        graph = planarity.PGraph(([1, 2],))
        assert (
            graph.draw(
                output_type='text/plain',
                label_type='index',
            ) == '1\n|\n2\n \n'
        )

    def test_explicit_image_type_preserves_default_png(self, draw, tmp_path):
        default_output = tmp_path / 'default.png'
        explicit_output = tmp_path / 'explicit.png'
        assert draw(outfileName=str(default_output)) is None
        assert (
            draw(
                outfileName=str(explicit_output),
                output_type='image/png',
            ) is None
        )
        with (
            Image.open(default_output) as default,
            Image.open(explicit_output) as explicit
        ):
            assert explicit.size == default.size
            assert (
                explicit.convert('RGBA').tobytes() ==
                default.convert('RGBA').tobytes()
            )

    def test_graph_can_switch_between_text_and_image(self, tmp_path, edges):
        graph = planarity.PGraph(edges)
        text = graph.draw(output_type='text/plain', label_type='index')
        output = tmp_path / 'graph.png'
        assert graph.draw(outfileName=str(output)) is None
        with Image.open(output) as image:
            assert image.format == 'PNG'
        assert graph.draw(output_type='text/plain', label_type='index') == text

    def test_draw_rejects_null_byte_in_outfileName(self, draw, tmp_path):
        output = tmp_path / 'must-not-overwrite.txt'
        output.write_text('keep this')
        with pytest.raises(ValueError, match='null'):
            draw(
                outfileName=str(output) + '\0suffix',
                output_type='text/plain',
                label_type='index',
            )
        assert output.read_text() == 'keep this'
