"""Exercise color controls on real artists and rendered PNGs."""

import matplotlib

matplotlib.use('Agg')

import matplotlib.pyplot as plt
from matplotlib.collections import LineCollection, PatchCollection
from matplotlib.colors import to_rgba
from PIL import Image
import pytest

import planarity


EDGES = [('a', 'c'), ('a', 'd'), ('a', 'e'), ('b', 'c'), ('b', 'd'),
         ('b', 'e'), ('c', 'd'), ('c', 'e'), ('d', 'e')]


@pytest.fixture(autouse=True)
def isolated_figures():
    with matplotlib.rc_context():
        yield
    plt.close('all')


@pytest.fixture(params=['function', 'method'])
def draw(request):
    if request.param == 'function':
        return lambda **kwargs: planarity.draw(EDGES, **kwargs)
    return lambda **kwargs: planarity.PGraph(EDGES).draw(**kwargs)


@pytest.mark.parametrize('option,color', [
    ('facecolor', '#abcdef'),
    ('vertex_facecolor', 'gold'),
    ('vertex_bordercolor', (0.3, 0.2, 0.8)),
    ('vertex_label_facecolor', 'lightgreen'),
    ('vertex_label_bordercolor', '#aabbcc'),
    ('edge_linecolor', 'magenta'),
])
def test_individual_colors_reach_artists(draw, option, color):
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
        vertices = next(c for c in ax.collections if isinstance(c, PatchCollection))
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
def test_png_background_and_transparency(draw, tmp_path, transparent):
    output = tmp_path / 'colors.png'
    # A user's savefig style must not override an explicit draw() facecolor.
    matplotlib.rcParams['savefig.facecolor'] = 'red'
    draw(outfileName=str(output), facecolor='#abcdef', transparent=transparent,
         figsize=(4, 3), dpi=100)
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


def test_color_controls_combine_without_labels(draw, tmp_path):
    draw(labels=False, outfileName=str(tmp_path / 'no-labels.png'),
         facecolor='white', transparent=True, vertex_facecolor='yellow',
         vertex_bordercolor='black', vertex_label_facecolor='pink',
         vertex_label_bordercolor='green', edge_linecolor='red')
    assert not plt.gca().texts
    vertices = next(c for c in plt.gca().collections if isinstance(c, PatchCollection))
    assert tuple(vertices.get_facecolors()[0]) == pytest.approx(to_rgba('yellow'))
    assert tuple(vertices.get_edgecolors()[0]) == pytest.approx(to_rgba('black'))


def test_default_background_resets_after_custom_draw(draw):
    draw(facecolor='red')
    draw()
    assert plt.gcf().get_facecolor() == pytest.approx(to_rgba('#ffffff'))
    for text in plt.gca().texts:
        assert text.get_bbox_patch().get_facecolor() == to_rgba('white')
        assert text.get_bbox_patch().get_edgecolor() == to_rgba('black')


def test_existing_figure_options(draw):
    draw(figsize=(4, 3), dpi=120)
    assert tuple(plt.gcf().get_size_inches()) == pytest.approx((4, 3))
    assert plt.gcf().dpi == 120


def test_unknown_keyword_still_rejected(draw):
    with pytest.raises(ValueError, match='not a supported draw'):
        draw(vertex_colour='red')


def test_invalid_color_rejected(draw):
    with pytest.raises(ValueError, match='not-a-color'):
        draw(vertex_facecolor='not-a-color')


# draw() defaults the figure dpi to 100, so pad_inches of padding shows up
# in the saved image as pad_inches * 100 pixels of background on each side.
DEFAULT_DPI = 100

# draw() also defaults the figure facecolor to white, and the padding it
# leaves around the drawing has that same color, so a pixel counts as
# background when each channel is close to white. The slack keeps the
# anti-aliased pixels that blend background into ink from counting as ink.
BACKGROUND = (255, 255, 255)
BACKGROUND_SLACK = 8


def _background_run_length(image, start, step):
    """Walks from the start pixel in the step direction, counting how many
    background pixels are seen before the first non-background pixel.

    Fails the test if the walk reaches the far side of the image without
    meeting any ink, since then the padding is not being measured against
    the drawing at all.
    """
    x, y = start
    run = 0
    while 0 <= x < image.width and 0 <= y < image.height:
        pixel = image.getpixel((x, y))
        if max(abs(pixel[i] - BACKGROUND[i]) for i in range(3)) > BACKGROUND_SLACK:
            return run
        run += 1
        x, y = x + step[0], y + step[1]
    raise AssertionError(
        f'walked from {start} across the image without finding the drawing'
    )


def _assert_pad_inches(draw, tmp_path, pad_inches):
    output = tmp_path / f'pad-{pad_inches}.png'
    # EDGES is K5 minus an edge, drawn here on the custom 4x3 figure. The
    # padding has to come out right on a caller-chosen figure size, not
    # only on the default one.
    draw(outfileName=str(output), pad_inches=pad_inches, figsize=(4, 3))
    with Image.open(output) as saved:
        image = saved.convert('RGBA')
        width, height = image.size
        # The padding is only meaningful in pixels if the saved image really
        # is the requested figsize at the default dpi.
        assert (width, height) == (4 * DEFAULT_DPI, 3 * DEFAULT_DPI)

        expected = round(pad_inches * DEFAULT_DPI)
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
            run = _background_run_length(image, start, step)
            # The measured run can deviate from pad_inches * dpi by a pixel
            # or two: anti-aliasing blends the outermost drawing pixels
            # into the background, and when vertices are drawn with a
            # border (vertex_bordercolor) the border widens them, which
            # measured one pixel short of the expected run. Two pixels of
            # slack absorbs that, while still failing if the padding is off
            # by a whole step between the tested values (0.1 inch = 10
            # pixels at the default dpi).
            assert abs(run - expected) <= 2, (side, run, expected)


def test_draw_pad_inches_controls_output_padding(draw, tmp_path):
    for pad_inches in (0.0, 0.1, 0.5):
        _assert_pad_inches(draw, tmp_path, pad_inches)


def test_draw_text():
    # ascii() is going to be deprecated in favor of calling draw() (#94),
    # so its rendering test lives with the drawing tests until then.
    e = ([1,2],)
    P = planarity.PGraph(e)
    s = P.ascii()#.decode()
    assert s == '1\n|\n2\n \n'

